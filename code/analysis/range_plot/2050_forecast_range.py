import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
from sqlalchemy import create_engine

# Keep text editable in vector PDF output
mpl.rcParams["pdf.fonttype"] = 42
mpl.rcParams["ps.fonttype"] = 42


# ============================================================
# 1. Settings
# ============================================================
TARGET_YEAR = 2050

# figures are written to <repo>/figures/range_plot
REPO_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
SCRIPT_DIR = os.path.join(REPO_DIR, "figures", "range_plot")
os.makedirs(SCRIPT_DIR, exist_ok=True)
OUTPUT_PDF = os.path.join(SCRIPT_DIR, f"national_electricity_forecast_{TARGET_YEAR}_range_plot.pdf")
OUTPUT_PNG = os.path.join(SCRIPT_DIR, f"national_electricity_forecast_{TARGET_YEAR}_range_plot.png")


# ============================================================
# 2. Database connection
# ============================================================
engine = create_engine(
    os.environ.get(
        "DC_FORECAST_DB_URL",
        "mysql+mysqlconnector://root@127.0.0.1/us_dc_energy_forecast",
    )
)


# ============================================================
# 3. Load all forecast data
# ============================================================
query = """
SELECT 
    v.year,
    v.demand_TWh,
    m.source,
    m.organization,
    m.scenario_original,
    m.scenario_standardized,
    m.region_type,
    CONCAT(m.source, ' | ', m.scenario_original) AS curve
FROM forecast_values v
JOIN forecast_metadata m
    ON v.forecast_id = m.forecast_id
ORDER BY 
    curve,
    v.year
"""

with engine.connect() as conn:
    df = pd.read_sql(query, conn)


# ============================================================
# 4. Basic cleaning
# ============================================================
df["year"] = df["year"].astype(int)
df["demand_TWh"] = df["demand_TWh"].astype(float)

df["source"] = df["source"].astype(str).str.strip()
df["scenario_original"] = df["scenario_original"].astype(str).str.strip()
df["scenario_standardized"] = df["scenario_standardized"].astype(str).str.strip()
df["region_type"] = df["region_type"].astype(str).str.strip()

df = df.sort_values(by=["curve", "year"])

print("Raw data shape:", df.shape)
print("Number of curves:", df["curve"].nunique())


# ============================================================
# 5. Keep national-level forecasts only
# ============================================================
df = df[df["region_type"].str.lower() == "national"].copy()

print("After national filtering:", df.shape)
print("Number of national curves:", df["curve"].nunique())


# ============================================================
# 6. Extract / interpolate target-year value for each curve
# ============================================================
records = []

for curve, group in df.groupby("curve"):
    group = group.sort_values("year").drop_duplicates(subset=["year"])

    years = group["year"].to_numpy()
    demands = group["demand_TWh"].to_numpy()

    # Skip curves that do not cover the target year
    if TARGET_YEAR < years.min() or TARGET_YEAR > years.max():
        continue

    # If TARGET_YEAR exists, np.interp returns the exact value.
    # Otherwise, it linearly interpolates between surrounding years.
    demand_target = np.interp(TARGET_YEAR, years, demands)

    records.append({
        "source": group["source"].iloc[0],
        "organization": group["organization"].iloc[0],
        "scenario_original": group["scenario_original"].iloc[0],
        "scenario_standardized": group["scenario_standardized"].iloc[0],
        "curve": curve,
        "year": TARGET_YEAR,
        "demand_TWh": demand_target,
        "min_year": years.min(),
        "max_year": years.max()
    })

df_target = pd.DataFrame(records)

if df_target.empty:
    raise ValueError(f"No curves cover {TARGET_YEAR}. Please check database year ranges.")


# ============================================================
# 7. Remove outdated EIA and standardize latest EIA label
# ============================================================

df_target = df_target[
    df_target["source"].astype(str).str.strip() != "EIA"
].copy()

df_target["source"] = df_target["source"].replace({
    "EIA 2026": "EIA AEO 2026"
})

print(f"\nExtracted/interpolated {TARGET_YEAR} curve-level data after EIA adjustment:")
print(df_target[["source", "scenario_original", "scenario_standardized", "demand_TWh"]])
print("\nNumber of curves used:", len(df_target))


# ============================================================
# 8. Classify scenarios into low / base / high
# ============================================================
def classify_scenario(row):
    scenario_std = str(row["scenario_standardized"]).lower()
    scenario_ori = str(row["scenario_original"]).lower()
    text = scenario_std + " " + scenario_ori

    # Low cases
    if "low" in text or "lower" in text:
        return "low"

    # High cases
    if "high" in text or "upper" in text:
        return "high"

    # Base / mid / reference cases
    if (
        "mid" in text
        or "medium" in text
        or "reference" in text
        or "baseline" in text
        or "ref" in text
        or "2.8%" in text
        or "current trajectory" in text
        or "central" in text
    ):
        return "base"

    # If not clear, treat as base-like single forecast
    return "base"


df_target["scenario_class"] = df_target.apply(classify_scenario, axis=1)


# ============================================================
# 9. Aggregate to institution-level range plot data
# ============================================================
plot_records = []

for source, group in df_target.groupby("source"):
    low_values = group.loc[group["scenario_class"] == "low", "demand_TWh"]
    base_values = group.loc[group["scenario_class"] == "base", "demand_TWh"]
    high_values = group.loc[group["scenario_class"] == "high", "demand_TWh"]

    # Base value:
    # If multiple base-like cases exist, use their average.
    if len(base_values) > 0:
        base_value = base_values.mean()
        base_note = "base/mid/reference average" if len(base_values) > 1 else "base/mid/reference"
    else:
        # If no base case exists, use midpoint/mean of available forecasts.
        base_value = group["demand_TWh"].mean()
        base_note = "mean of available cases"

    # Low and high bounds:
    # Use explicit low/high when available; otherwise use min/max available.
    if len(low_values) > 0:
        low_bound = low_values.min()
    else:
        low_bound = group["demand_TWh"].min()

    if len(high_values) > 0:
        high_bound = high_values.max()
    else:
        high_bound = group["demand_TWh"].max()

    # For single-case sources, avoid creating a fake range.
    if len(group) == 1:
        low_bound = base_value
        high_bound = base_value

    plot_records.append({
        "source": source,
        "base_TWh": base_value,
        "low_TWh": low_bound,
        "high_TWh": high_bound,
        "n_curves": len(group),
        "base_note": base_note
    })

df_plot = pd.DataFrame(plot_records)

# Sort by base forecast value
df_plot = df_plot.sort_values(by="base_TWh").reset_index(drop=True)

print(f"\nInstitution-level {TARGET_YEAR} plot data:")
print(df_plot)


# ============================================================
# 10. Plot: base point + low-high range bar + caps
# ============================================================
x = np.arange(len(df_plot))

fig, ax = plt.subplots(figsize=(14, 8))

# Range bars: vertical rectangular bars from low to high
range_heights = df_plot["high_TWh"] - df_plot["low_TWh"]

ax.bar(
    x,
    range_heights,
    bottom=df_plot["low_TWh"],
    width=0.28,
    edgecolor="black",
    linewidth=1.0,
    alpha=0.35,
    label="Low–high forecast range"
)

# Thin vertical center line for clearer interval display
ax.vlines(
    x,
    df_plot["low_TWh"],
    df_plot["high_TWh"],
    linewidth=2.0,
    color="black",
    alpha=0.85
)

# Caps at low and high
cap_width = 0.16

for i, row in df_plot.iterrows():
    ax.hlines(
        row["low_TWh"],
        i - cap_width,
        i + cap_width,
        linewidth=2.0,
        color="black"
    )
    ax.hlines(
        row["high_TWh"],
        i - cap_width,
        i + cap_width,
        linewidth=2.0,
        color="black"
    )

# Base / mid points
ax.scatter(
    x,
    df_plot["base_TWh"],
    s=95,
    marker="s",
    edgecolor="black",
    linewidth=1.0,
    zorder=5,
    label="Base / mid forecast"
)


# ============================================================
# 11. Non-intrusive labels for base / mid point
# ============================================================

global_range = df_plot["high_TWh"].max() - df_plot["low_TWh"].min()
label_y_offset = global_range * 0.025
label_x_offset = 0.08

for i, row in df_plot.iterrows():
    has_range = row["high_TWh"] > row["low_TWh"]

    if has_range:
        label_y = row["high_TWh"] + label_y_offset
    else:
        label_y = row["base_TWh"] + label_y_offset

    ax.text(
        i + label_x_offset,
        label_y,
        f"{row['base_TWh']:.0f}",
        ha="left",
        va="bottom",
        fontsize=9,
        zorder=6,
        bbox=dict(
            facecolor="white",
            edgecolor="none",
            alpha=0.80,
            pad=1.5
        )
    )


# ============================================================
# 12. Formatting
# ============================================================
ax.set_title(
    f"U.S. National Electricity Demand Forecast Ranges in {TARGET_YEAR}",
    fontsize=17,
    pad=18
)

ax.set_ylabel(
    f"Electricity Demand in {TARGET_YEAR} (TWh)",
    fontsize=13
)

ax.set_xlabel(
    "Forecast Source",
    fontsize=13
)

ax.set_xticks(x)
ax.set_xticklabels(
    df_plot["source"],
    rotation=35,
    ha="right",
    fontsize=11
)

ax.grid(axis="y", linestyle="--", alpha=0.35)
ax.set_axisbelow(True)

y_min = df_plot["low_TWh"].min()
y_max = df_plot["high_TWh"].max()
padding = (y_max - y_min) * 0.14

ax.set_ylim(y_min - padding, y_max + padding)

ax.legend(
    fontsize=11,
    frameon=False,
    loc="upper left"
)

plt.tight_layout()


# ============================================================
# 13. Save and show
# ============================================================
# Save vector PDF
plt.savefig(
    OUTPUT_PDF,
    format="pdf",
    bbox_inches="tight"
)

# Save ultra-high-resolution PNG
plt.savefig(
    OUTPUT_PNG,
    format="png",
    dpi=1200,
    bbox_inches="tight"
)

plt.show()

print("\nSaved files:")
print("PDF:", OUTPUT_PDF)
print("PNG:", OUTPUT_PNG)