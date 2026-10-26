import os
import re
import textwrap
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
from matplotlib.colors import TwoSlopeNorm
from sqlalchemy import create_engine


# ============================================================
# 1. Settings
# ============================================================
TARGET_YEAR = 2030

# heatmaps are written to <repo>/figures/heatmap
REPO_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
SCRIPT_DIR = os.path.join(REPO_DIR, "figures", "heatmap")
OUTPUT_DIR = os.path.join(SCRIPT_DIR, f"diff_heatmaps_{TARGET_YEAR}")
os.makedirs(OUTPUT_DIR, exist_ok=True)

CENTRAL_OUTPUT_PDF = os.path.join(
    OUTPUT_DIR,
    f"institution_central_difference_heatmap_{TARGET_YEAR}.pdf"
)

CENTRAL_OUTPUT_PNG = os.path.join(
    OUTPUT_DIR,
    f"institution_central_difference_heatmap_{TARGET_YEAR}.png"
)

WITHIN_OUTPUT_DIR = os.path.join(
    OUTPUT_DIR,
    "within_institution_heatmaps"
)
os.makedirs(WITHIN_OUTPUT_DIR, exist_ok=True)

# Keep text editable in vector PDF output
mpl.rcParams["pdf.fonttype"] = 42
mpl.rcParams["ps.fonttype"] = 42


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

for col in ["source", "organization", "scenario_original", "scenario_standardized", "region_type"]:
    df[col] = df[col].astype(str).str.strip()

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

    if TARGET_YEAR < years.min() or TARGET_YEAR > years.max():
        continue

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
    "EIA 2026": "EIA AEO 2026",
    "EIA_AEO2026": "EIA AEO 2026",
    "EIA AEO2026": "EIA AEO 2026"
})

df_target["curve_label"] = (
    df_target["source"].astype(str)
    + " | "
    + df_target["scenario_original"].astype(str)
)

print(f"\nExtracted/interpolated {TARGET_YEAR} data after EIA adjustment:")
print(df_target[["source", "scenario_original", "scenario_standardized", "demand_TWh"]])
print("\nNumber of curves used:", len(df_target))


# ============================================================
# 8. Scenario classification and central-case priority
# ============================================================
def classify_scenario(row):
    scenario_std = str(row["scenario_standardized"]).lower()
    scenario_ori = str(row["scenario_original"]).lower()
    text = scenario_std + " " + scenario_ori

    if "low" in text or "lower" in text:
        return "low"

    if "high" in text or "upper" in text:
        return "high"

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

    return "base"


def central_priority(row):
    """
    Lower score = stronger preference as the institution-level central case.
    """
    scenario_std = str(row["scenario_standardized"]).lower()
    scenario_ori = str(row["scenario_original"]).lower()
    text = scenario_std + " " + scenario_ori

    if "medium" in text and "moderate" in text:
        return 0
    if "mid" in text and "moderate" in text:
        return 1
    if "medium" in text:
        return 2
    if "mid" in text:
        return 3
    if "baseline" in text:
        return 4
    if "reference" in text and "moderate" in text:
        return 5
    if "reference" in text or "ref" in text:
        return 6
    if "current trajectory" in text:
        return 7
    if "2.8%" in text:
        return 8
    if "central" in text:
        return 9

    return 99


df_target["scenario_class"] = df_target.apply(classify_scenario, axis=1)
df_target["central_priority"] = df_target.apply(central_priority, axis=1)


# ============================================================
# 9. Label helpers
# ============================================================
def clean_filename(text):
    text = str(text)
    text = re.sub(r"[^A-Za-z0-9]+", "_", text)
    text = text.strip("_")
    return text


def wrap_label(label, width=18):
    """
    Wrap long labels so tick labels do not collide.
    """
    label = str(label)
    return "\n".join(textwrap.wrap(label, width=width))


# ============================================================
# 10. Robust heatmap plotting helper
# ============================================================
def plot_signed_difference_heatmap(
    values,
    labels,
    main_title,
    subtitle,
    output_pdf,
    output_png,
    figsize=(12, 10),
    value_fontsize=8,
    label_fontsize=9,
    title_fontsize=16,
    subtitle_fontsize=10,
    rotate_x=45,
    wrap_width=18,
    left=0.23,
    right=0.86,
    bottom=0.23,
    top=0.86
):
    values = np.asarray(values, dtype=float)
    labels = [wrap_label(label, width=wrap_width) for label in labels]

    n = len(values)

    diff_matrix = values[:, None] - values[None, :]
    masked_matrix = diff_matrix.copy()
    np.fill_diagonal(masked_matrix, np.nan)

    max_abs_diff = np.nanmax(np.abs(masked_matrix))
    if max_abs_diff == 0 or np.isnan(max_abs_diff):
        max_abs_diff = 1

    norm = TwoSlopeNorm(
        vmin=-max_abs_diff,
        vcenter=0,
        vmax=max_abs_diff
    )

    cmap = plt.cm.RdBu_r.copy()
    cmap.set_bad(color="white")

    fig = plt.figure(figsize=figsize)

    gs = fig.add_gridspec(
        nrows=1,
        ncols=2,
        width_ratios=[1, 0.045],
        left=left,
        right=right,
        bottom=bottom,
        top=top,
        wspace=0.08
    )

    ax = fig.add_subplot(gs[0, 0])
    cax = fig.add_subplot(gs[0, 1])

    # Figure-level title and subtitle
    title_center_x = (left + right) / 2

    fig.text(
        title_center_x,
        0.965,
        main_title,
        ha="center",
        va="top",
        fontsize=title_fontsize
    )

    fig.text(
        title_center_x,
        0.925,
        subtitle,
        ha="center",
        va="top",
        fontsize=subtitle_fontsize
    )

    im = ax.imshow(
        masked_matrix,
        cmap=cmap,
        norm=norm,
        aspect="equal"
    )

    ax.set_xticks(np.arange(n))
    ax.set_yticks(np.arange(n))

    ax.set_xticklabels(
        labels,
        rotation=rotate_x,
        ha="right",
        rotation_mode="anchor",
        fontsize=label_fontsize
    )

    ax.set_yticklabels(
        labels,
        fontsize=label_fontsize
    )

    # Grid lines
    ax.set_xticks(np.arange(-0.5, n, 1), minor=True)
    ax.set_yticks(np.arange(-0.5, n, 1), minor=True)

    ax.grid(
        which="minor",
        color="gray",
        linestyle="-",
        linewidth=0.4,
        alpha=0.45
    )

    ax.tick_params(which="minor", bottom=False, left=False)
    ax.tick_params(axis="both", which="major", length=0)

    # Annotate cells and diagonal crosses
    for i in range(n):
        for j in range(n):
            if i == j:
                ax.plot(
                    [j - 0.36, j + 0.36],
                    [i - 0.36, i + 0.36],
                    color="black",
                    linewidth=1.0
                )
                ax.plot(
                    [j - 0.36, j + 0.36],
                    [i + 0.36, i - 0.36],
                    color="black",
                    linewidth=1.0
                )
                continue

            value = diff_matrix[i, j]
            cell_label = f"{value:+.0f}"

            text_color = "white" if abs(value) > max_abs_diff * 0.55 else "black"

            ax.text(
                j,
                i,
                cell_label,
                ha="center",
                va="center",
                fontsize=value_fontsize,
                color=text_color
            )

    cbar = fig.colorbar(
        im,
        cax=cax
    )

    cbar.set_label(
        f"Forecast Difference in {TARGET_YEAR} (TWh)",
        fontsize=10,
        labelpad=12
    )

    cbar.ax.tick_params(labelsize=9)

    plt.savefig(
        output_pdf,
        format="pdf",
        bbox_inches="tight",
        pad_inches=0.20
    )

    plt.savefig(
        output_png,
        format="png",
        dpi=1200,
        bbox_inches="tight",
        pad_inches=0.20
    )

    plt.close(fig)

    print("Saved:", output_pdf)
    print("Saved:", output_png)


# ===============================================================
# 11. Institution-level central/mid difference heatmap
# ===============================================================
central_records = []

for source, group in df_target.groupby("source"):
    group = group.copy()
    base_group = group[group["scenario_class"] == "base"].copy()

    if len(base_group) > 0:
        selected = base_group.sort_values(
            by=["central_priority", "scenario_original"]
        ).iloc[0]

        central_records.append({
            "source": source,
            "central_label": source,
            "selected_scenario": selected["scenario_original"],
            "central_TWh": selected["demand_TWh"],
            "selection_method": "selected central/base scenario"
        })

    else:
        low = group["demand_TWh"].min()
        high = group["demand_TWh"].max()
        midpoint = (low + high) / 2

        central_records.append({
            "source": source,
            "central_label": source,
            "selected_scenario": "low-high midpoint",
            "central_TWh": midpoint,
            "selection_method": "low-high midpoint"
        })

df_central = pd.DataFrame(central_records)
df_central = df_central.sort_values(by="central_TWh").reset_index(drop=True)

print(f"\nInstitution-level central/mid values for {TARGET_YEAR}:")
print(df_central)

central_labels = df_central["central_label"].tolist()
central_values = df_central["central_TWh"].to_numpy()

plot_signed_difference_heatmap(
    values=central_values,
    labels=central_labels,
    main_title=f"Institution-Level Central Forecast Differences in {TARGET_YEAR}",
    subtitle="Cell value = row institution central forecast − column institution central forecast (TWh)",
    output_pdf=CENTRAL_OUTPUT_PDF,
    output_png=CENTRAL_OUTPUT_PNG,
    figsize=(12.5, 10.5),
    value_fontsize=8.5,
    label_fontsize=10,
    title_fontsize=17,
    subtitle_fontsize=10.5,
    rotate_x=45,
    wrap_width=18,
    left=0.22,
    right=0.88,
    bottom=0.24,
    top=0.86
)

central_table_path = os.path.join(
    OUTPUT_DIR,
    f"institution_central_case_selection_{TARGET_YEAR}.csv"
)

df_central.to_csv(central_table_path, index=False)
print("Saved:", central_table_path)


# ==============================================================
# 12. Within-institution scenario difference heatmaps
# ==============================================================
def within_scenario_sort_key(row):
    scenario_class = row["scenario_class"]

    if scenario_class == "low":
        group_rank = 0
    elif scenario_class == "base":
        group_rank = 1
    elif scenario_class == "high":
        group_rank = 2
    else:
        group_rank = 9

    return group_rank, row["central_priority"], str(row["scenario_original"])


for source, group in df_target.groupby("source"):
    group = group.copy()

    if len(group) < 2:
        continue

    group["_sort_tuple"] = group.apply(within_scenario_sort_key, axis=1)
    group = group.sort_values(by="_sort_tuple").reset_index(drop=True)

    labels = group["scenario_original"].tolist()
    values = group["demand_TWh"].to_numpy()

    n = len(group)

    safe_source = clean_filename(source)

    output_pdf = os.path.join(
        WITHIN_OUTPUT_DIR,
        f"{safe_source}_within_scenario_difference_heatmap_{TARGET_YEAR}_vector.pdf"
    )

    output_png = os.path.join(
        WITHIN_OUTPUT_DIR,
        f"{safe_source}_within_scenario_difference_heatmap_{TARGET_YEAR}_1200dpi.png"
    )

    if n <= 3:
        plot_signed_difference_heatmap(
            values=values,
            labels=labels,
            main_title=f"{source}: Within-Scenario Differences in {TARGET_YEAR}",
            subtitle="Cell value = row scenario forecast − column scenario forecast (TWh)",
            output_pdf=output_pdf,
            output_png=output_png,
            figsize=(8.0, 7.2),
            value_fontsize=9,
            label_fontsize=9,
            title_fontsize=14,
            subtitle_fontsize=9.5,
            rotate_x=35,
            wrap_width=18,
            left=0.26,
            right=0.86,
            bottom=0.26,
            top=0.86
        )

    elif n <= 6:
        plot_signed_difference_heatmap(
            values=values,
            labels=labels,
            main_title=f"{source}: Within-Scenario Differences in {TARGET_YEAR}",
            subtitle="Cell value = row scenario forecast − column scenario forecast (TWh)",
            output_pdf=output_pdf,
            output_png=output_png,
            figsize=(9.5, 8.5),
            value_fontsize=8,
            label_fontsize=8.5,
            title_fontsize=14,
            subtitle_fontsize=9.5,
            rotate_x=40,
            wrap_width=18,
            left=0.27,
            right=0.87,
            bottom=0.28,
            top=0.86
        )

    else:
        plot_signed_difference_heatmap(
            values=values,
            labels=labels,
            main_title=f"{source}: Within-Scenario Differences in {TARGET_YEAR}",
            subtitle="Cell value = row scenario forecast − column scenario forecast (TWh)",
            output_pdf=output_pdf,
            output_png=output_png,
            figsize=(12.5, 11.0),
            value_fontsize=6.5,
            label_fontsize=7.5,
            title_fontsize=14,
            subtitle_fontsize=9.5,
            rotate_x=45,
            wrap_width=16,
            left=0.28,
            right=0.88,
            bottom=0.30,
            top=0.86
        )


# ============================================================
# 13. Print output locations
# ============================================================
print("\nDone.")
print("Main output folder:")
print(os.path.abspath(OUTPUT_DIR))
print("\nWithin-institution output folder:")
print(os.path.abspath(WITHIN_OUTPUT_DIR))