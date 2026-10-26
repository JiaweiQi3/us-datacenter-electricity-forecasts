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
        "EIA_AEO2026": "EIA",
        "EIA AEO2026": "EIA",
        "EIA_AEO2025": "EIA",
        "EIA AEO2025": "EIA",
        "EIA": "EIA",
        "IEA": "IEA",
        "ICF": "ICF",
        "Citi": "Citi",
        "Citi Research": "Citi",
        "S&P": "S&P",
        "S&P Global": "S&P",
        "NREL EFS": "NREL",
        "NREL": "NREL",
        "BP": "BP",
        "Princeton": "Princeton",
        "LCRI": "LCRI",
        "LBNL": "LBNL",
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


institution_order = [
    "EIA",
    "IEA",
    "ICF",
    "Citi",
    "S&P",
    "NREL",
    "BP",
    "Princeton",
    "LCRI",
    "LBNL",
]


def simplify_scenario_label(row):
    source = row["source_clean"]
    scenario = row["scenario_original"].strip()
    scenario_lower = scenario.lower()
    std = row["scenario_standardized"].lower()

    if source == "EIA":
        if "reference" in scenario_lower:
            return "Reference"
        if "counterfactual" in scenario_lower or "baseline" in scenario_lower:
            return "Baseline"
        if "high economic" in scenario_lower:
            return "High economic growth"
        if "low economic" in scenario_lower:
            return "Low economic growth"
        if "high oil" in scenario_lower or "high oil and gas" in scenario_lower:
            return "High oil and gas supply"
        if "low oil" in scenario_lower or "low oil and gas" in scenario_lower:
            return "Low oil and gas supply"
        if "high electricity" in scenario_lower:
            return "High electricity demand"
        if "high zero" in scenario_lower:
            return "High zero-carbon cost"
        if "low zero" in scenario_lower:
            return "Low zero-carbon cost"
        return scenario

    if source == "NREL":
        return scenario.replace("_", " ")

    if source == "LCRI":
        if "lower" in scenario_lower:
            return "Lower bound"
        if "upper" in scenario_lower:
            return "Upper bound"
        if "central" in scenario_lower:
            return "Central"
        return scenario

    if source == "Princeton":
        if std in ["low", "mid", "high"]:
            return std.capitalize()
        return scenario

    if source == "BP":
        if "below" in scenario_lower:
            return "Below 2°"
        if "current" in scenario_lower:
            return "Current trajectory"
        return scenario

    if source == "S&P":
        if "lower" in scenario_lower:
            return "Lower bound"
        if "upper" in scenario_lower:
            return "Upper bound"
        return scenario

    if source == "LBNL":
        if "high" in scenario_lower:
            return "High data center share"
        if "low" in scenario_lower:
            return "Low data center share"
        return scenario

    if source == "Citi":
        return "2.8% CAGR"

    if source == "ICF":
        return "Growth-based estimate"

    if source == "IEA":
        return "Derived pathway"

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
        or "below 2" in scenario
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

    upper_bound = y_max + y_range * 0.12
    lower_bound = y_min - y_range * 0.12

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
        min_gap_ratio=0.060 if n_curves >= 8 else 0.045
    )

    x_range = max(x_max - x_min, 1)
    x_shift = x_range * 0.025

    for _, row in label_df.iterrows():
        x_text = row["x"] + x_shift

        if x_text > x_max - x_range * 0.03:
            x_text = row["x"] - x_shift
            ha = "right"
        else:
            ha = "left"

        ax.annotate(
            row["label"],
            xy=(row["x"], row["y"]),
            xytext=(x_text, row["y_label"]),
            fontsize=10 if n_curves >= 8 else 10.5,
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


def add_panel_internal_labels(ax, label_points, x_min, x_max, y_min, y_max, n_labels):
    label_df = pd.DataFrame(label_points)

    if label_df.empty:
        return

    label_df = adjust_label_positions(
        label_df,
        y_min=y_min,
        y_max=y_max,
        min_gap_ratio=0.060 if n_labels >= 3 else 0.045
    )

    x_range = max(x_max - x_min, 1)
    x_shift = x_range * 0.030

    for _, row in label_df.iterrows():
        x_text = row["x"] + x_shift
        ha = "left"

        if x_text > x_max - x_range * 0.08:
            x_text = row["x"] - x_shift
            ha = "right"

        ax.annotate(
            row["label"],
            xy=(row["x"], row["y"]),
            xytext=(x_text, row["y_label"]),
            fontsize=9.2,
            color=row["color"],
            va="center",
            ha=ha,
            arrowprops=dict(
                arrowstyle="-",
                color=row["color"],
                lw=0.7,
                alpha=0.55
            ),
            clip_on=True
        )


def add_panel_end_labels(ax, label_points, x_min, x_max, y_min, y_max, n_labels):
    label_df = pd.DataFrame(label_points)

    if label_df.empty:
        return

    label_df = adjust_label_positions(
        label_df,
        y_min=y_min,
        y_max=y_max,
        min_gap_ratio=0.060 if n_labels >= 3 else 0.045
    )

    x_range = max(x_max - x_min, 1)
    label_x = x_max + x_range * 0.035

    for _, row in label_df.iterrows():
        ax.annotate(
            row["label"],
            xy=(row["x"], row["y"]),
            xytext=(label_x, row["y_label"]),
            fontsize=9.2,
            color=row["color"],
            va="center",
            ha="left",
            arrowprops=dict(
                arrowstyle="-",
                color=row["color"],
                lw=0.7,
                alpha=0.55
            ),
            clip_on=True
        )


REPO_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
output_dir = os.path.join(REPO_DIR, "figures", "appendix_national_trends")
os.makedirs(output_dir, exist_ok=True)


for institution in institution_order:
    if institution in ["EIA", "NREL"]:
        continue

    inst_df = df[df["source_clean"] == institution].copy()

    if inst_df.empty:
        print(f"Skipping {institution}: no data found.")
        continue

    curves = sorted(inst_df["curve"].unique())
    n_curves = len(curves)

    if n_curves >= 4:
        fig, ax = plt.subplots(figsize=(11.2, 6.8))
    elif n_curves >= 2:
        fig, ax = plt.subplots(figsize=(10.2, 6.4))
    else:
        fig, ax = plt.subplots(figsize=(9.6, 6.2))

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
            linewidth=2.7,
            marker="o",
            markersize=4.6,
            alpha=0.9,
            label=label
        )

        anchor_idx = int(round((len(group) - 1) * 0.62))
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

    left_margin = max(x_range * 0.035, 0.35)
    right_margin = max(x_range * 0.035, 0.35)
    y_margin = max(y_range * 0.22, 80)

    ax.set_xlim(x_min - left_margin, x_max + right_margin)
    ax.set_ylim(y_min - y_margin, y_max + y_margin)

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
    title = f"{institution} National Electricity Demand Forecast Trajectories"

    if pub_year:
        title += f" ({pub_year})"

    ax.set_title(title, fontsize=16, pad=14)
    ax.set_xlabel("Year", fontsize=13)
    ax.set_ylabel("Electricity Demand (TWh)", fontsize=13)
    ax.grid(True, linestyle="--", alpha=0.35)
    ax.tick_params(axis="both", labelsize=11)

    ax.legend(
        fontsize=9.5 if n_curves <= 6 else 8.5,
        frameon=False,
        loc="upper left",
        ncol=1
    )

    plt.tight_layout()

    filename_base = f"national_appendix_{institution.replace('&', 'and').replace(' ', '_')}"
    pdf_path = os.path.join(output_dir, f"{filename_base}.pdf")
    png_path = os.path.join(output_dir, f"{filename_base}.png")

    plt.savefig(pdf_path, bbox_inches="tight")
    plt.savefig(png_path, dpi=600, bbox_inches="tight")
    plt.close(fig)

    print(f"Saved: {pdf_path}")
    print(f"Saved: {png_path}")


def plot_eia_special(df, output_dir):
    inst_df = df[df["source_clean"] == "EIA"].copy()

    if inst_df.empty:
        print("Skipping EIA: no data found.")
        return

    groups = {
        "Reference and baseline cases": ["reference", "baseline", "counterfactual"],
        "Economic growth cases": ["economic"],
        "Oil and gas supply cases": ["oil", "gas"],
        "Electricity demand and zero-carbon cost cases": ["electricity", "zero-carbon", "zero carbon"],
    }

    fig, axes = plt.subplots(
        2,
        2,
        figsize=(15.5, 10),
        sharex=True,
        sharey=True
    )

    axes = axes.flatten()
    cmap = plt.get_cmap("tab10")

    x_min_all = inst_df["year"].min()
    x_max_all = inst_df["year"].max()
    y_min_all = inst_df["demand_TWh"].min()
    y_max_all = inst_df["demand_TWh"].max()

    x_range = max(x_max_all - x_min_all, 1)
    y_range = max(y_max_all - y_min_all, 1)

    for ax, (panel_title, keywords) in zip(axes, groups.items()):
        panel_df = inst_df[
            inst_df["scenario_original"]
            .str.lower()
            .apply(lambda x: any(k in x for k in keywords))
        ].copy()

        curves = sorted(panel_df["curve"].unique())
        label_points = []

        for i, curve in enumerate(curves):
            group = panel_df[panel_df["curve"] == curve].sort_values("year")
            first_row = group.iloc[0]

            label = first_row["scenario_label"]
            linestyle = get_line_style(first_row)
            color = cmap(i % 10)

            ax.plot(
                group["year"],
                group["demand_TWh"],
                color=color,
                linestyle=linestyle,
                linewidth=2.6,
                marker="o",
                markersize=4.2,
                alpha=0.9,
                label=label
            )

            anchor_idx = int(round((len(group) - 1) * 0.68))
            anchor_idx = min(max(anchor_idx, 0), len(group) - 1)
            anchor = group.iloc[anchor_idx]

            label_points.append({
                "label": label,
                "x": float(anchor["year"]),
                "y": float(anchor["demand_TWh"]),
                "color": color
            })

        ax.set_title(panel_title, fontsize=13, pad=10)
        ax.grid(True, linestyle="--", alpha=0.35)
        ax.tick_params(axis="both", labelsize=10)

        ax.legend(
            fontsize=8.5,
            frameon=False,
            loc="upper left"
        )

        add_panel_internal_labels(
            ax=ax,
            label_points=label_points,
            x_min=x_min_all,
            x_max=x_max_all,
            y_min=panel_df["demand_TWh"].min(),
            y_max=panel_df["demand_TWh"].max(),
            n_labels=len(label_points)
        )

    for ax in axes:
        ax.set_xlim(x_min_all - x_range * 0.02, x_max_all + x_range * 0.03)
        ax.set_ylim(y_min_all - y_range * 0.13, y_max_all + y_range * 0.13)

    fig.suptitle(
        "EIA National Electricity Demand Forecast Trajectories (2026)",
        fontsize=17,
        y=0.98
    )

    fig.supxlabel("Year", fontsize=13)
    fig.supylabel("Electricity Demand (TWh)", fontsize=13)

    plt.tight_layout(rect=[0.03, 0.03, 1, 0.95])

    pdf_path = os.path.join(output_dir, "national_appendix_EIA.pdf")
    png_path = os.path.join(output_dir, "national_appendix_EIA.png")

    plt.savefig(pdf_path, bbox_inches="tight")
    plt.savefig(png_path, dpi=600, bbox_inches="tight")
    plt.close(fig)

    print(f"Saved: {pdf_path}")
    print(f"Saved: {png_path}")


def plot_nrel_special(df, output_dir):
    inst_df = df[df["source_clean"] == "NREL"].copy()

    if inst_df.empty:
        print("Skipping NREL: no data found.")
        return

    groups = {
        "High electrification": ["high"],
        "Medium electrification": ["medium"],
        "Reference electrification": ["reference"],
    }

    fig, axes = plt.subplots(
        1,
        3,
        figsize=(18.5, 5.8),
        sharex=True,
        sharey=True
    )

    colors = {
        "Rapid": "#1f77b4",
        "Moderate": "#ff7f0e",
        "Slow": "#2ca02c",
    }

    x_min_all = inst_df["year"].min()
    x_max_all = inst_df["year"].max()
    y_min_all = inst_df["demand_TWh"].min()
    y_max_all = inst_df["demand_TWh"].max()

    x_range = max(x_max_all - x_min_all, 1)
    y_range = max(y_max_all - y_min_all, 1)

    for ax, (panel_title, keywords) in zip(axes, groups.items()):
        panel_df = inst_df[
            inst_df["scenario_original"]
            .str.lower()
            .apply(lambda x: any(k in x for k in keywords))
        ].copy()

        curves = sorted(panel_df["curve"].unique())
        label_points = []

        for curve in curves:
            group = panel_df[panel_df["curve"] == curve].sort_values("year")
            first_row = group.iloc[0]

            label_full = first_row["scenario_label"]

            if "Rapid" in label_full:
                label = "Rapid"
                color = colors["Rapid"]
            elif "Moderate" in label_full:
                label = "Moderate"
                color = colors["Moderate"]
            elif "Slow" in label_full:
                label = "Slow"
                color = colors["Slow"]
            else:
                label = label_full
                color = "#333333"

            ax.plot(
                group["year"],
                group["demand_TWh"],
                color=color,
                linestyle="-",
                linewidth=2.8,
                marker="o",
                markersize=4.8,
                alpha=0.9,
                label=label
            )

            last = group.iloc[-1]

            label_points.append({
                "label": label,
                "x": float(last["year"]),
                "y": float(last["demand_TWh"]),
                "color": color
            })

        ax.set_title(panel_title, fontsize=13, pad=10)
        ax.grid(True, linestyle="--", alpha=0.35)
        ax.tick_params(axis="both", labelsize=10)
        ax.legend(fontsize=9.5, frameon=False, loc="upper left")

        add_panel_end_labels(
            ax=ax,
            label_points=label_points,
            x_min=x_min_all,
            x_max=x_max_all,
            y_min=panel_df["demand_TWh"].min(),
            y_max=panel_df["demand_TWh"].max(),
            n_labels=len(label_points)
        )

    for ax in axes:
        ax.set_xlim(x_min_all - x_range * 0.02, x_max_all + x_range * 0.13)
        ax.set_ylim(y_min_all - y_range * 0.12, y_max_all + y_range * 0.12)

    fig.suptitle(
        "NREL National Electricity Demand Forecast Trajectories (2018)",
        fontsize=17,
        y=0.98
    )

    fig.supxlabel("Year", fontsize=13)
    fig.supylabel("Electricity Demand (TWh)", fontsize=13)

    plt.tight_layout(rect=[0.03, 0.03, 1, 0.93])

    pdf_path = os.path.join(output_dir, "national_appendix_NREL.pdf")
    png_path = os.path.join(output_dir, "national_appendix_NREL.png")

    plt.savefig(pdf_path, bbox_inches="tight")
    plt.savefig(png_path, dpi=600, bbox_inches="tight")
    plt.close(fig)

    print(f"Saved: {pdf_path}")
    print(f"Saved: {png_path}")


plot_eia_special(df, output_dir)
plot_nrel_special(df, output_dir)

print("\nAll appendix national trend plots have been generated.")