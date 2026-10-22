import os
import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine
from matplotlib.patches import Patch
from matplotlib.lines import Line2D

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


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

df = df.sort_values(by=["source", "scenario_original", "year"])
df["year"] = df["year"].astype(int)
df["demand_TWh"] = df["demand_TWh"].astype(float)
df["source"] = df["source"].astype(str)
df["scenario_original"] = df["scenario_original"].astype(str)
df["scenario_standardized"] = df["scenario_standardized"].astype(str)


# ============================================================
# 4. Source name cleaning
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


# ============================================================
# 5. Keep only institutions with data in all target years
# ============================================================
target_years = [2025, 2028, 2030]

df_target = df[df["year"].isin(target_years)].copy()

source_year_count = (
    df_target
    .groupby("source_clean")["year"]
    .nunique()
)

valid_sources = source_year_count[
    source_year_count == len(target_years)
].index.tolist()

plot_source_order = [
    "EPRI",
    "BCG",
    "BNEF",
    "McKinsey",
    "IEA",
    "Rhodium",
    "Jefferies",
    "LBNL",
    "S&P",
]

plot_source_order = [s for s in plot_source_order if s in valid_sources]

plot_df = df_target[df_target["source_clean"].isin(plot_source_order)].copy()


# ============================================================
# 6. Build range data: low, mid/base, high for each source-year
# ============================================================
def select_base_value(group):
    temp = group.copy()
    temp["scenario_lower"] = temp["scenario_original"].str.lower()
    temp["std_lower"] = temp["scenario_standardized"].str.lower()

    mid_rows = temp[temp["std_lower"] == "mid"]
    if not mid_rows.empty:
        return mid_rows["demand_TWh"].mean()

    keywords = ["base", "baseline", "medium", "mid", "projected", "central"]
    pattern = "|".join(keywords)

    base_rows = temp[temp["scenario_lower"].str.contains(pattern, na=False)]
    if not base_rows.empty:
        return base_rows["demand_TWh"].mean()

    return temp["demand_TWh"].mean()


range_records = []

for (source, year), group in plot_df.groupby(["source_clean", "year"]):
    low_value = group["demand_TWh"].min()
    high_value = group["demand_TWh"].max()
    base_value = select_base_value(group)

    range_records.append({
        "source_clean": source,
        "year": year,
        "low": low_value,
        "base": base_value,
        "high": high_value,
        "n_curves": group["curve"].nunique()
    })

range_df = pd.DataFrame(range_records)


# ============================================================
# 7. Build single-axis grouped x positions
# ============================================================
bar_width = 0.34
within_gap = 0.68      # tighter spacing within each year group
year_gap = 1.65        # moderate spacing between year groups

plot_records = []
year_centers = []

current_x = 0

for year in target_years:
    year_df = range_df[range_df["year"] == year].copy()

    year_df["source_clean"] = pd.Categorical(
        year_df["source_clean"],
        categories=plot_source_order,
        ordered=True
    )

    year_df = year_df.sort_values("source_clean").reset_index(drop=True)

    group_start = current_x

    for _, row in year_df.iterrows():
        plot_records.append({
            "x": current_x,
            "year": year,
            "source_clean": row["source_clean"],
            "low": row["low"],
            "base": row["base"],
            "high": row["high"]
        })

        current_x += within_gap

    group_end = current_x - within_gap
    year_centers.append((year, (group_start + group_end) / 2))

    current_x += year_gap

plot_pos_df = pd.DataFrame(plot_records)


# ============================================================
# 8. Calculate percentage growth from previous benchmark year
# ============================================================
plot_pos_df["pct_growth"] = None

for source in plot_pos_df["source_clean"].unique():
    source_data = plot_pos_df[
        plot_pos_df["source_clean"] == source
    ].sort_values("year")

    previous_base = None

    for idx, row in source_data.iterrows():
        current_base = row["base"]

        if previous_base is None:
            plot_pos_df.loc[idx, "pct_growth"] = None
        else:
            pct_growth = (current_base / previous_base - 1) * 100
            plot_pos_df.loc[idx, "pct_growth"] = pct_growth

        previous_base = current_base


# ============================================================
# 9. Plot single-axis range bars
# ============================================================
fig, ax = plt.subplots(figsize=(20, 8))

range_color = "#9ecae1"
base_color = "#ff7f0e"

# More compact y-axis range
y_min = range_df["low"].min()
y_max = range_df["high"].max()

y_lower = max(0, y_min - 35)
y_upper = y_max + 160

# Use one aligned horizontal level for all growth labels
growth_label_y_value = y_max + 105

for row in plot_pos_df.itertuples():
    x = row.x
    low = row.low
    base = row.base
    high = row.high
    has_range = abs(high - low) > 1e-6

    # Low–high range bar
    if has_range:
        ax.bar(
            x,
            high - low,
            bottom=low,
            width=bar_width,
            color=range_color,
            edgecolor="black",
            linewidth=1.4,
            alpha=0.65,
            zorder=2
        )

        cap_width = bar_width * 1.25

        ax.hlines(
            y=low,
            xmin=x - cap_width / 2,
            xmax=x + cap_width / 2,
            color="black",
            linewidth=2.2,
            zorder=3
        )

        ax.hlines(
            y=high,
            xmin=x - cap_width / 2,
            xmax=x + cap_width / 2,
            color="black",
            linewidth=2.2,
            zorder=3
        )

    else:
        ax.hlines(
            y=base,
            xmin=x - bar_width / 2,
            xmax=x + bar_width / 2,
            color="black",
            linewidth=2.2,
            zorder=3
        )

    # Base / mid marker
    ax.scatter(
        x,
        base,
        marker="s",
        s=95,
        color=base_color,
        edgecolor="black",
        linewidth=1.2,
        zorder=4
    )

    # Base / mid value label
    if has_range:
        ax.text(
            x + 0.20,
            base,
            f"{base:.0f}",
            ha="left",
            va="center",
            fontsize=11,
            fontweight="bold",
            zorder=5
        )
    else:
        ax.text(
            x,
            base + 16,
            f"{base:.0f}",
            ha="center",
            va="bottom",
            fontsize=11,
            fontweight="bold",
            zorder=5
        )

    # Percentage growth label for 2028 and 2030
    if row.pct_growth is not None:
        growth_label = (
            f"+{row.pct_growth:.0f}%"
            if row.pct_growth >= 0
            else f"{row.pct_growth:.0f}%"
        )

        ax.text(
            x,
            growth_label_y_value,
            growth_label,
            ha="center",
            va="bottom",
            fontsize=11,
            fontweight="bold",
            rotation=0,
            color="black",
            zorder=5
        )


# ============================================================
# 10. X-axis labels and year labels
# ============================================================
ax.set_xticks(plot_pos_df["x"])
ax.set_xticklabels(
    plot_pos_df["source_clean"],
    rotation=90,
    ha="center",
    fontsize=12
)

# Year labels below each group
for year, center in year_centers:
    ax.text(
        center,
        -0.20,
        str(year),
        ha="center",
        va="top",
        fontsize=18,
        fontweight="bold",
        transform=ax.get_xaxis_transform()
    )

# Vertical separators between year groups
for i in range(len(year_centers) - 1):
    _, center_left = year_centers[i]
    _, center_right = year_centers[i + 1]
    separator_x = (center_left + center_right) / 2

    ax.axvline(
        separator_x,
        color="gray",
        linestyle="--",
        linewidth=0.8,
        alpha=0.22,
        zorder=1
    )


# ============================================================
# 11. Legend and formatting
# ============================================================
legend_handles = [
    Line2D(
        [0],
        [0],
        marker="s",
        color="none",
        markerfacecolor=base_color,
        markeredgecolor="black",
        markersize=11,
        label="Base / mid forecast"
    ),
    Patch(
        facecolor=range_color,
        edgecolor="black",
        alpha=0.65,
        label="Low–high forecast range"
    )
]

ax.legend(
    handles=legend_handles,
    fontsize=14,
    frameon=False,
    loc="upper left"
)

ax.set_ylabel(
    "U.S. Data Center Electricity Demand (TWh)",
    fontsize=15
)

ax.set_title(
    "U.S. Data Center Electricity Demand Forecast Ranges in 2025, 2028, and 2030",
    fontsize=20,
    pad=14
)

ax.grid(axis="y", linestyle="--", alpha=0.35)
ax.tick_params(axis="y", labelsize=12)

ax.set_ylim(y_lower, y_upper)

plt.subplots_adjust(bottom=0.25)
plt.tight_layout()


# ============================================================
# 12. Save and show
# ============================================================
plt.savefig(os.path.join(SCRIPT_DIR, "dc_trend.pdf"), bbox_inches="tight")
plt.savefig(os.path.join(SCRIPT_DIR, "dc_trend.png"), dpi=1200, bbox_inches="tight")

plt.show()