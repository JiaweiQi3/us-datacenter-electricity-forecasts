import os
import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine
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
FROM forecast_values v
JOIN forecast_metadata m
    ON v.forecast_id = m.forecast_id
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
        "EIA_AEO2026": "EIA",
        "EIA AEO2026": "EIA",
        "EIA_AEO2025": "EIA",
        "EIA": "EIA",
        "NREL EFS": "NREL",
        "NREL": "NREL",
        "Princeton": "Princeton",
        "LCRI": "LCRI",
        "LBNL": "LBNL",
        "IEA": "IEA",
        "ICF": "ICF",
        "Citi": "Citi",
        "Citi Research": "Citi",
        "S&P": "S&P",
        "S&P Global": "S&P",
        "BP": "BP",
    }

    return mapping.get(source, source)


df["source_clean"] = df["source"].apply(clean_source_name)

publication_year = {
    "EIA": 2026,
    "IEA": 2026,
    "ICF": 2026,
    "Citi": 2025,
    "S&P": 2025,
    "NREL": 2018,
    "BP": 2025,
    "Princeton": 2021,
    "LCRI": 2024,
    "LBNL": 2024,
}

source_colors = {
    "EIA": "#1f77b4",
    "NREL": "#2ca02c",
    "LCRI": "#ff7f0e",
    "Princeton": "#9467bd",
    "BP": "#d62728",
    "ICF": "#8c564b",
    "Citi": "#e377c2",
    "S&P": "#7f7f7f",
    "IEA": "#17becf",
    "LBNL": "#bcbd22",
}


# ============================================================
# 5. Select one representative curve per institution
# ============================================================
def choose_best_curve(source_df, source_name):
    """
    Select one representative curve for institutions with clear mid/base/reference trajectories.
    """

    curve_info = (
        source_df[["curve", "scenario_original", "scenario_standardized"]]
        .drop_duplicates()
        .copy()
    )

    curve_info["scenario_lower"] = curve_info["scenario_original"].str.lower()
    curve_info["std_lower"] = curve_info["scenario_standardized"].str.lower()

    # Institution-specific priority rules
    priority_rules = {
        "EIA": ["reference", "baseline", "counterfactual"],
        "NREL": ["medium_moderate", "medium moderate", "mid", "moderate"],
        "LCRI": ["central"],
        "Princeton": ["mid"],
        "BP": ["current"],
        "ICF": ["growth-based", "growth"],
        "Citi": ["2.8", "cagr"],
        "IEA": ["derived"],
    }

    keywords = priority_rules.get(source_name, [])

    for keyword in keywords:
        matched = curve_info[
            curve_info["scenario_lower"].str.contains(keyword, case=False, na=False)
        ]
        if not matched.empty:
            return matched.iloc[0]["curve"]

    # General fallback: use standardized mid scenario if available
    matched = curve_info[curve_info["std_lower"] == "mid"]
    if not matched.empty:
        return matched.iloc[0]["curve"]

    # Final fallback: use the first available curve
    return curve_info.iloc[0]["curve"]


def average_low_high(source_df, source_name):
    """
    Create one representative curve by averaging all available curves by year.
    This is used for institutions such as S&P or LBNL when only low/high curves are available.
    """

    rep = (
        source_df
        .groupby("year", as_index=False)["demand_TWh"]
        .mean()
    )

    rep["source_clean"] = source_name
    rep["curve"] = f"{source_name} representative average"
    rep["line_label"] = source_name

    return rep


def select_representative_curves(df):
    representative_list = []

    for source_name, source_df in df.groupby("source_clean"):

        # For low/high-only institutions, use average curve
        if source_name in ["S&P", "LBNL"]:
            rep = average_low_high(source_df, source_name)
            representative_list.append(rep)
            continue

        selected_curve = choose_best_curve(source_df, source_name)

        rep = source_df[source_df["curve"] == selected_curve].copy()
        rep["line_label"] = source_name

        representative_list.append(
            rep[["year", "demand_TWh", "source_clean", "curve", "line_label"]]
        )

    return pd.concat(representative_list, ignore_index=True)


rep_df = select_representative_curves(df)


# ============================================================
# 6. Plot representative curves
# ============================================================
fig, ax = plt.subplots(figsize=(18, 11))

for source_name, group in rep_df.groupby("source_clean"):
    group = group.sort_values("year")

    ax.plot(
        group["year"],
        group["demand_TWh"],
        color=source_colors.get(source_name, "#333333"),
        linestyle="-",
        linewidth=3.0,
        alpha=0.9
    )


# ============================================================
# 7. Direct line-end labels
# ============================================================
label_points = []

for source_name, group in rep_df.groupby("source_clean"):
    group = group.sort_values("year")
    last = group.iloc[-1]

    label_points.append({
        "label": source_name,
        "x": int(last["year"]),
        "y": float(last["demand_TWh"]),
        "color": source_colors.get(source_name, "#333333")
    })

label_df = pd.DataFrame(label_points)
label_df = label_df.sort_values("y").reset_index(drop=True)

y_min = rep_df["demand_TWh"].min()
y_max = rep_df["demand_TWh"].max()
upper_limit = y_max + 400

# Vertical spacing to reduce label overlap
min_gap = 90
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
        xytext=(row["x"] + 0.8, row["y_label"]),
        fontsize=15,
        color=row["color"],
        va="center",
        ha="left",
        arrowprops=dict(
            arrowstyle="-",
            color=row["color"],
            lw=0.9,
            alpha=0.65
        )
    )


# ============================================================
# 8. Institution-level legend with publication year
# ============================================================
legend_sources = [
    "EIA",
    "NREL",
    "LCRI",
    "Princeton",
    "BP",
    "ICF",
    "Citi",
    "S&P",
    "IEA",
    "LBNL",
]

legend_handles = []

for source in legend_sources:
    if source in rep_df["source_clean"].unique():
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
    fontsize=18,
    ncol=2,
    frameon=False,
    loc="upper left",
    bbox_to_anchor=(0.01, 0.99),
    title="Legend",
    title_fontsize=18
)


# ============================================================
# 9. Formatting
# ============================================================
ax.set_xlabel("Year", fontsize=15)
ax.set_ylabel("Electricity Demand (TWh)", fontsize=15)

ax.set_title(
    "U.S. National Electricity Demand Representative Forecast Trajectories",
    fontsize=20,
    pad=15
)

ax.grid(True, linestyle="--", alpha=0.3)

x_min = rep_df["year"].min()
x_max = rep_df["year"].max()

ax.set_xlim(x_min - 1, x_max + 5)
ax.set_ylim(y_min - 150, upper_limit)

ax.tick_params(axis="both", labelsize=13)

plt.tight_layout()


# ============================================================
# 10. Save and show
# ============================================================
plt.savefig(os.path.join(SCRIPT_DIR, "plot_rep.pdf"), bbox_inches="tight")
plt.savefig(os.path.join(SCRIPT_DIR, "plot_rep.png"), dpi=1200, bbox_inches="tight")

plt.show()