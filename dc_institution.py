import os
import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine


engine = create_engine(
    os.environ.get(
        "DC_FORECAST_DB_URL",
        "mysql+mysqlconnector://root@127.0.0.1/us_dc_energy_forecast",
    )
)


query = """
SELECT 
    v.year,
    v.demand_TWh,
    v.share_percent,
    m.source,
    m.organization,
    m.scenario_original,
    m.scenario_standardized,
    m.unit_original,
    CONCAT(m.source, ' | ', m.scenario_original) AS curve
FROM dc_forecast_values v
JOIN dc_forecast_metadata m
    ON v.dc_forecast_id = m.dc_forecast_id
ORDER BY 
    curve,
    v.year
"""


with engine.connect() as conn:
    df = pd.read_sql(query, conn)


df = df.sort_values(by=["curve", "year"])
df["year"] = df["year"].astype(int)
df["demand_TWh"] = df["demand_TWh"].astype(float)
df["source"] = df["source"].astype(str)
df["scenario_original"] = df["scenario_original"].astype(str)
df["scenario_standardized"] = df["scenario_standardized"].astype(str)


def clean_source_name(source):
    source = source.strip()

    mapping = {
        "LBNL": "LBNL",
        "EPRI": "EPRI",
        "BCG": "BCG",
        "Boston Consulting Group": "BCG",
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


institution_order = [
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


def simplify_scenario_label(row):
    source = row["source_clean"]
    scenario = row["scenario_original"].strip()
    scenario_lower = scenario.lower()
    std = row["scenario_standardized"].lower()

    if source == "LBNL":
        if "high" in scenario_lower or std == "high":
            return "High"
        if "low" in scenario_lower or std == "low":
            return "Low"
        return scenario

    if source == "EPRI":
        if "high" in scenario_lower or std == "high":
            return "High"
        if "medium" in scenario_lower or "mid" in scenario_lower or std == "mid":
            return "Medium"
        if "low" in scenario_lower or std == "low":
            return "Low"
        return scenario

    if source == "BCG":
        if "high" in scenario_lower or std == "high":
            return "High demand"
        if "base" in scenario_lower or "lower" in scenario_lower or std in ["mid", "low"]:
            return "Base"
        return scenario

    if source == "BNEF":
        return "Converted from GW"

    if source == "McKinsey":
        return "Medium scenario"

    if source == "IEA":
        return "Base case"

    if source == "Rhodium":
        if "high" in scenario_lower or std == "high":
            return "High growth"
        if "baseline" in scenario_lower or "base" in scenario_lower or std == "mid":
            return "Baseline"
        return scenario

    if source == "S&P":
        if "high" in scenario_lower or "upper" in scenario_lower or std == "high":
            return "High"
        if "low" in scenario_lower or "lower" in scenario_lower or std == "low":
            return "Low"
        return scenario

    if source == "Jefferies":
        return "Digitized estimate"

    return scenario


df["scenario_label"] = df.apply(simplify_scenario_label, axis=1)


def get_line_style(row):
    scenario = row["scenario_original"].lower()
    std = row["scenario_standardized"].lower()

    if std == "low" or "low" in scenario or "lower" in scenario:
        return "--"

    if (
        std == "high"
        or "high" in scenario
        or "upper" in scenario
        or "higher" in scenario
    ):
        return "-."

    return "-"


def adjust_label_positions(label_df, y_min, y_max, min_gap_ratio=0.055):
    if label_df.empty:
        return label_df

    label_df = label_df.sort_values("y").reset_index(drop=True).copy()

    y_range = max(y_max - y_min, 1)
    min_gap = y_range * min_gap_ratio

    adjusted_y = []

    for y in label_df["y"].tolist():
        if not adjusted_y:
            adjusted_y.append(y)
        else:
            adjusted_y.append(max(y, adjusted_y[-1] + min_gap))

    label_df["y_label"] = adjusted_y

    upper_bound = y_max + y_range * 0.14
    lower_bound = y_min - y_range * 0.14

    overflow = label_df["y_label"].max() - upper_bound
    if overflow > 0:
        label_df["y_label"] = label_df["y_label"] - overflow

    underflow = lower_bound - label_df["y_label"].min()
    if underflow > 0:
        label_df["y_label"] = label_df["y_label"] + underflow

    return label_df


def add_internal_labels(ax, label_points, x_min, x_max, y_min, y_max, n_curves):
    label_df = pd.DataFrame(label_points)

    if label_df.empty:
        return

    label_df = adjust_label_positions(
        label_df,
        y_min=y_min,
        y_max=y_max,
        min_gap_ratio=0.080 if n_curves >= 3 else 0.060
    )

    x_range = max(x_max - x_min, 1)
    x_shift = x_range * 0.030

    for _, row in label_df.iterrows():
        x_text = row["x"] + x_shift
        ha = "left"

        if x_text > x_max - x_range * 0.05:
            x_text = row["x"] - x_shift
            ha = "right"

        ax.annotate(
            row["label"],
            xy=(row["x"], row["y"]),
            xytext=(x_text, row["y_label"]),
            fontsize=10.5,
            color=row["color"],
            va="center",
            ha=ha,
            arrowprops=dict(
                arrowstyle="-",
                color=row["color"],
                lw=0.8,
                alpha=0.55
            ),
            clip_on=True
        )


output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "appendix_dc_trends")
os.makedirs(output_dir, exist_ok=True)


for institution in institution_order:
    inst_df = df[df["source_clean"] == institution].copy()

    if inst_df.empty:
        print(f"Skipping {institution}: no data found.")
        continue

    curves = sorted(inst_df["curve"].unique())
    n_curves = len(curves)

    if n_curves >= 4:
        fig, ax = plt.subplots(figsize=(11.5, 6.8))
    elif n_curves >= 2:
        fig, ax = plt.subplots(figsize=(10.5, 6.4))
    else:
        fig, ax = plt.subplots(figsize=(9.8, 6.2))

    cmap = plt.get_cmap("tab10")
    colors = [cmap(i % 10) for i in range(n_curves)]

    label_points = []

    for i, curve in enumerate(curves):
        group = inst_df[inst_df["curve"] == curve].sort_values("year")
        first_row = group.iloc[0]

        label = first_row["scenario_label"]
        linestyle = get_line_style(first_row)
        color = colors[i]

        ax.plot(
            group["year"],
            group["demand_TWh"],
            color=color,
            linestyle=linestyle,
            linewidth=2.8,
            marker="o",
            markersize=5.0,
            alpha=0.92,
            label=label
        )

        anchor_idx = int(round((len(group) - 1) * 0.60))
        anchor_idx = min(max(anchor_idx, 0), len(group) - 1)
        anchor = group.iloc[anchor_idx]

        label_points.append({
            "label": label,
            "x": float(anchor["year"]),
            "y": float(anchor["demand_TWh"]),
            "color": color
        })

    x_min = inst_df["year"].min()
    x_max = inst_df["year"].max()
    y_min = inst_df["demand_TWh"].min()
    y_max = inst_df["demand_TWh"].max()

    x_range = max(x_max - x_min, 1)
    y_range = max(y_max - y_min, 1)

    left_margin = max(x_range * 0.035, 0.25)
    right_margin = max(x_range * 0.035, 0.25)
    y_margin = max(y_range * 0.25, 35)

    ax.set_xlim(x_min - left_margin, x_max + right_margin)
    ax.set_ylim(max(0, y_min - y_margin), y_max + y_margin)

    add_internal_labels(
        ax=ax,
        label_points=label_points,
        x_min=x_min,
        x_max=x_max,
        y_min=y_min,
        y_max=y_max,
        n_curves=n_curves
    )

    pub_year = publication_year.get(institution, "")
    title = f"{institution} Data Center Electricity Demand Forecast Trajectories"

    if pub_year:
        title += f" ({pub_year})"

    ax.set_title(title, fontsize=16, pad=14)
    ax.set_xlabel("Year", fontsize=13)
    ax.set_ylabel("U.S. Data Center Electricity Demand (TWh)", fontsize=13)

    ax.grid(True, linestyle="--", alpha=0.35)
    ax.tick_params(axis="both", labelsize=11)

    years = sorted(inst_df["year"].unique())
    ax.set_xticks(years)

    ax.legend(
        fontsize=10 if n_curves <= 4 else 9,
        frameon=False,
        loc="upper left",
        ncol=1
    )

    plt.tight_layout()

    filename_base = f"dc_appendix_{institution.replace('&', 'and').replace(' ', '_')}"
    pdf_path = os.path.join(output_dir, f"{filename_base}.pdf")
    png_path = os.path.join(output_dir, f"{filename_base}.png")

    plt.savefig(pdf_path, bbox_inches="tight")
    plt.savefig(png_path, dpi=600, bbox_inches="tight")

    plt.close(fig)

    print(f"Saved: {pdf_path}")
    print(f"Saved: {png_path}")


print("\nAll appendix data center trend plots have been generated.")