import os
import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine
from matplotlib.lines import Line2D

# figures are written to <repo>/figures/trajectory
REPO_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
SCRIPT_DIR = os.path.join(REPO_DIR, "figures", "trajectory")
os.makedirs(SCRIPT_DIR, exist_ok=True)


# ============================================================
# 1. Database connection
# ============================================================
engine = create_engine(
    os.environ.get(
        "DC_FORECAST_DB_URL",
        "mysql+mysqlconnector://root@127.0.0.1/us_dc_energy_forecast",
    )
)


# ============================================================
# 2. SQL query
# ============================================================
query = """
SELECT 
    v.year,
    v.demand_TWh,
    m.source,
    m.scenario_original,
    m.scenario_standardized,
    CONCAT(m.source, ' | ', m.scenario_original) AS curve
FROM dc_forecast_values v
JOIN dc_forecast_metadata m
    ON v.dc_forecast_id = m.dc_forecast_id
ORDER BY 
    curve,
    v.year
"""


# ============================================================
# 3. Load and preprocess data
# ============================================================
with engine.connect() as conn:
    df = pd.read_sql(query, conn)

df = df.sort_values(by=["curve", "year"])
df["year"] = df["year"].astype(int)
df["demand_TWh"] = df["demand_TWh"].astype(float)
df["source"] = df["source"].astype(str)
df["scenario_original"] = df["scenario_original"].astype(str)
df["scenario_standardized"] = df["scenario_standardized"].astype(str)


# ============================================================
# 4. Source names and publication years
# ============================================================
def clean_source_name(source):
    source = source.strip()

    mapping = {
        "LBNL": "LBNL",
        "EPRI": "EPRI",
        "BCG": "BCG",
        "BloombergNEF": "BNEF",
        "Bloomberg NEF": "BNEF",
        "BNEF": "BNEF",
        "McKinsey": "McKinsey",
        "McKinsey & Company": "McKinsey",
        "IEA": "IEA",
        "Rhodium": "Rhodium",
        "Rhodium Group": "Rhodium",
        "S&P": "S&P",
        "S&P Global": "S&P",
        "Jefferies": "Jefferies",
    }

    return mapping.get(source, source)


df["source_clean"] = df["source"].apply(clean_source_name)

publication_year = {
    "LBNL": 2024,
    "EPRI": 2026,
    "BCG": 2026,
    "BNEF": 2025,
    "McKinsey": 2024,
    "IEA": 2025,
    "Rhodium": 2026,
    "S&P": 2024,
    "Jefferies": 2024,
}

source_colors = {
    "LBNL": "#bcbd22",
    "EPRI": "#1f77b4",
    "BCG": "#d62728",
    "BNEF": "#9467bd",
    "McKinsey": "#2ca02c",
    "IEA": "#17becf",
    "Rhodium": "#ff7f0e",
    "S&P": "#7f7f7f",
    "Jefferies": "#8c564b",
}


# ============================================================
# 5. Simplified line labels
# ============================================================
def classify_scenario(row):
    source = row["source_clean"]
    scenario = row["scenario_original"].lower()
    std = row["scenario_standardized"].lower()

    if source == "LBNL":
        if "high" in scenario or std == "high":
            return "LBNL high"
        elif "low" in scenario or std == "low":
            return "LBNL low"
        else:
            return "LBNL mid"

    if source == "EPRI":
        if "high" in scenario or std == "high":
            return "EPRI high"
        elif "low" in scenario or std == "low":
            return "EPRI low"
        elif "medium" in scenario or "mid" in scenario or std == "mid":
            return "EPRI mid"
        else:
            return "EPRI"

    if source == "BCG":
        if "high" in scenario or std == "high":
            return "BCG high"
        elif "low" in scenario or "base" in scenario or std == "low":
            return "BCG low"
        else:
            return "BCG mid"

    if source == "Rhodium":
        if "high" in scenario or std == "high":
            return "Rhodium high"
        elif "baseline" in scenario or "base" in scenario or std == "mid":
            return "Rhodium base"
        else:
            return "Rhodium"

    if source == "S&P":
        if "high" in scenario or "upper" in scenario or std == "high":
            return "S&P high"
        elif "low" in scenario or "lower" in scenario or std == "low":
            return "S&P low"
        else:
            return "S&P"

    if source == "BNEF":
        return "BNEF"

    if source == "McKinsey":
        return "McKinsey"

    if source == "IEA":
        return "IEA"

    if source == "Jefferies":
        return "Jefferies"

    return source


df["line_label"] = df.apply(classify_scenario, axis=1)


# ============================================================
# 6. Plot all forecast curves
# ============================================================
fig, ax = plt.subplots(figsize=(18, 11))

for curve, group in df.groupby("curve"):
    group = group.sort_values("year")
    first_row = group.iloc[0]
    source = first_row["source_clean"]

    ax.plot(
        group["year"],
        group["demand_TWh"],
        color=source_colors.get(source, "#333333"),
        linestyle="-",
        linewidth=2.8,
        alpha=0.80
    )


# ============================================================
# 7. Direct line-end labels, merged by simplified label
# ============================================================
label_points = []

for curve, group in df.groupby("curve"):
    group = group.sort_values("year")
    last = group.iloc[-1]

    label_points.append({
        "label": last["line_label"],
        "x": int(last["year"]),
        "y": float(last["demand_TWh"]),
        "color": source_colors.get(last["source_clean"], "#333333")
    })

label_df = pd.DataFrame(label_points)

# Merge repeated labels if any
label_df = (
    label_df
    .groupby("label", as_index=False)
    .agg({
        "x": "max",
        "y": "mean",
        "color": "first"
    })
)

label_df = label_df.sort_values("y").reset_index(drop=True)

y_min = df["demand_TWh"].min()
y_max = df["demand_TWh"].max()
upper_limit = y_max + 160

# Vertical spacing to reduce label overlap
min_gap = 30
adjusted_y = []

for y in label_df["y"].tolist():
    if not adjusted_y:
        adjusted_y.append(y)
    else:
        adjusted_y.append(max(y, adjusted_y[-1] + min_gap))

label_df["y_label"] = adjusted_y
label_df["y_label"] = label_df["y_label"].clip(lower=y_min, upper=upper_limit)

for _, row in label_df.iterrows():
    ax.annotate(
        row["label"],
        xy=(row["x"], row["y"]),
        xytext=(row["x"] + 0.25, row["y_label"]),
        fontsize=14,
        color=row["color"],
        va="center",
        ha="left",
        arrowprops=dict(
            arrowstyle="-",
            color=row["color"],
            lw=0.8,
            alpha=0.6
        )
    )


# ============================================================
# 8. Institution-level legend with publication year
# ============================================================
legend_sources = [
    "LBNL",
    "EPRI",
    "BCG",
    "BNEF",
    "McKinsey",
    "IEA",
    "Rhodium",
    "S&P",
    "Jefferies",
]

legend_handles = []

for source in legend_sources:
    if source in df["source_clean"].unique():
        legend_handles.append(
            Line2D(
                [0],
                [0],
                color=source_colors.get(source, "#333333"),
                lw=4,
                label=f"{source} ({publication_year[source]})"
            )
        )

ax.legend(
    handles=legend_handles,
    fontsize=17,
    ncol=2,
    frameon=False,
    loc="upper left",
    bbox_to_anchor=(0.01, 0.99),
    title="Legend",
    title_fontsize=17
)


# ============================================================
# 9. Formatting
# ============================================================
ax.set_xlabel("Year", fontsize=15)
ax.set_ylabel("U.S. Data Center Electricity Demand (TWh)", fontsize=15)

ax.set_title(
    "U.S. Data Center Electricity Demand Forecast Trajectories",
    fontsize=20,
    pad=15
)

ax.grid(True, linestyle="--", alpha=0.3)

x_min = df["year"].min()
x_max = df["year"].max()

ax.set_xlim(x_min - 0.5, x_max + 1.7)
ax.set_ylim(y_min - 30, upper_limit)

ax.tick_params(axis="both", labelsize=13)

ax.set_xticks(sorted(df["year"].unique()))

plt.tight_layout()


# ============================================================
# 10. Save and show
# ============================================================
plt.savefig(os.path.join(SCRIPT_DIR, "dc_plot_full.pdf"), bbox_inches="tight")
plt.savefig(os.path.join(SCRIPT_DIR, "dc_plot_full.png"), dpi=1200, bbox_inches="tight")

plt.show()