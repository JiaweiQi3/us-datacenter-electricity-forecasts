import os
import numpy as np
import pandas as pd
from sqlalchemy import create_engine


# ============================================================
# 1. Settings
# ============================================================

DATABASE_URL = os.environ.get(
    "DC_FORECAST_DB_URL",
    "mysql+mysqlconnector://root@127.0.0.1/us_dc_energy_forecast",
)

TARGET_YEARS = [2030, 2035, 2050]

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_EXCEL = os.path.join(OUTPUT_DIR, "national_ranking_tables.xlsx")

# Ranking order:
# True  = highest forecast / highest CAGR ranked first
# False = lowest forecast / lowest CAGR ranked first
RANK_DESCENDING = True


# ============================================================
# 2. Helper functions
# ============================================================

def normalize_source_name(source: str) -> str:
    """Standardize source labels for table output."""
    source = str(source).strip()

    replacements = {
        "EIA_AEO2026": "EIA AEO 2026",
        "EIA 2026": "EIA AEO 2026",
    }

    return replacements.get(source, source)


def classify_scenario(row) -> str:
    """
    Classify each curve into low / base / high.

    Priority:
    1. Use scenario_standardized if available.
    2. Fall back to scenario_original keyword matching.
    """
    scenario_std = str(row.get("scenario_standardized", "")).strip().lower()
    scenario_ori = str(row.get("scenario_original", "")).strip().lower()

    if scenario_std == "low":
        return "low"
    if scenario_std == "high":
        return "high"
    if scenario_std == "mid":
        return "base"

    text = scenario_ori

    if "low" in text or "lower" in text:
        return "low"
    if "high" in text or "upper" in text:
        return "high"
    if (
        "mid" in text
        or "medium" in text
        or "reference" in text
        or "baseline" in text
        or "base" in text
        or "central" in text
        or "current trajectory" in text
        or "2.8%" in text
    ):
        return "base"

    return "base"


def interpolate_value(group: pd.DataFrame, target_year: int) -> float:
    """
    Extract or linearly interpolate one curve's value for target_year.
    No extrapolation is allowed.
    """
    group = group.sort_values("year").drop_duplicates(subset=["year"])

    years = group["year"].to_numpy(dtype=float)
    values = group["demand_TWh"].to_numpy(dtype=float)

    if target_year < years.min() or target_year > years.max():
        return np.nan

    return float(np.interp(target_year, years, values))


def get_target_curve_values(df: pd.DataFrame, target_year: int) -> pd.DataFrame:
    """Create curve-level target-year values for all curves covering target_year."""
    records = []

    for curve, group in df.groupby("curve"):
        group = group.sort_values("year").drop_duplicates(subset=["year"])

        demand_target = interpolate_value(group, target_year)

        if np.isnan(demand_target):
            continue

        records.append({
            "source": group["source"].iloc[0],
            "organization": group["organization"].iloc[0],
            "scenario_original": group["scenario_original"].iloc[0],
            "scenario_standardized": group["scenario_standardized"].iloc[0],
            "scenario_class": group["scenario_class"].iloc[0],
            "curve": curve,
            "target_year": target_year,
            "target_value_TWh": demand_target,
            "curve_start_year": int(group["year"].min()),
            "curve_end_year": int(group["year"].max()),
        })

    return pd.DataFrame(records)


def representative_value_by_source(df_target: pd.DataFrame, target_year: int) -> pd.DataFrame:
    """
    Institution-level representative target-year value.

    Rule:
    - If one curve exists: use that curve.
    - If two curves exist: use the average of the two curves.
    - If three or more curves exist: use base / mid / reference / central curves if available.
      If no base curve exists, use the average of all available curves.
    """
    records = []

    for source, group in df_target.groupby("source"):
        group = group.copy()
        n_curves = len(group)

        if n_curves == 1:
            selected = group
            basis = "single curve"

        elif n_curves == 2:
            selected = group
            basis = "average of two available curves"

        else:
            base_group = group[group["scenario_class"] == "base"]

            if len(base_group) > 0:
                selected = base_group
                basis = "base / mid / reference / central case"
            else:
                selected = group
                basis = "average of all available curves"

        representative_value = selected["target_value_TWh"].mean()

        records.append({
            "target_year": target_year,
            "source": source,
            "organization": selected["organization"].iloc[0],
            "representative_value_TWh": representative_value,
            "n_curves_available": n_curves,
            "n_curves_used": len(selected),
            "scenario_basis": basis,
            "scenarios_used": "; ".join(selected["scenario_original"].astype(str).tolist()),
            "min_available_TWh": group["target_value_TWh"].min(),
            "max_available_TWh": group["target_value_TWh"].max(),
        })

    result = pd.DataFrame(records)

    result = result.sort_values(
        by="representative_value_TWh",
        ascending=not RANK_DESCENDING
    ).reset_index(drop=True)

    result.insert(0, "rank", np.arange(1, len(result) + 1))

    return result


def growth_ranking_by_source(df: pd.DataFrame, df_target: pd.DataFrame, target_year: int) -> pd.DataFrame:
    """
    Institution-level growth multiple and CAGR ranking.

    Uses the same representative curve-selection rule as the target-year ranking.

    For selected curves:
    - If one curve: use that curve's first available year.
    - If multiple curves: use the latest first year among selected curves as the common start year.
    - Start and target values are calculated by interpolation and averaged across selected curves.
    """
    records = []

    for source, group_target in df_target.groupby("source"):
        group_target = group_target.copy()
        n_curves = len(group_target)

        if n_curves == 1:
            selected_target = group_target
            basis = "single curve"

        elif n_curves == 2:
            selected_target = group_target
            basis = "average of two available curves"

        else:
            base_group = group_target[group_target["scenario_class"] == "base"]

            if len(base_group) > 0:
                selected_target = base_group
                basis = "base / mid / reference / central case"
            else:
                selected_target = group_target
                basis = "average of all available curves"

        selected_curves = selected_target["curve"].tolist()

        curve_data = df[df["curve"].isin(selected_curves)].copy()

        # Common start year ensures all selected curves can be averaged consistently.
        start_year = int(
            curve_data.groupby("curve")["year"].min().max()
        )

        if start_year >= target_year:
            continue

        start_values = []
        target_values = []

        for curve, g in curve_data.groupby("curve"):
            g = g.sort_values("year").drop_duplicates(subset=["year"])

            start_value = interpolate_value(g, start_year)
            target_value = interpolate_value(g, target_year)

            if np.isnan(start_value) or np.isnan(target_value):
                continue

            start_values.append(start_value)
            target_values.append(target_value)

        if len(start_values) == 0 or len(target_values) == 0:
            continue

        start_value_TWh = float(np.mean(start_values))
        target_value_TWh = float(np.mean(target_values))

        if start_value_TWh <= 0:
            continue

        growth_multiple = target_value_TWh / start_value_TWh
        cagr = growth_multiple ** (1 / (target_year - start_year)) - 1

        records.append({
            "target_year": target_year,
            "source": source,
            "organization": selected_target["organization"].iloc[0],
            "start_year": start_year,
            "start_value_TWh": start_value_TWh,
            "target_value_TWh": target_value_TWh,
            "growth_multiple": growth_multiple,
            "CAGR": cagr,
            "CAGR_percent": cagr * 100,
            "n_curves_available": n_curves,
            "n_curves_used": len(selected_target),
            "scenario_basis": basis,
            "scenarios_used": "; ".join(selected_target["scenario_original"].astype(str).tolist()),
        })

    result = pd.DataFrame(records)

    result = result.sort_values(
        by="CAGR",
        ascending=not RANK_DESCENDING
    ).reset_index(drop=True)

    result.insert(0, "rank", np.arange(1, len(result) + 1))

    return result


# ============================================================
# 3. Load national forecast data
# ============================================================

os.makedirs(OUTPUT_DIR, exist_ok=True)

engine = create_engine(DATABASE_URL)

query = """
SELECT 
    v.year,
    v.demand_TWh,
    m.source,
    m.organization,
    m.scenario_original,
    m.scenario_standardized,
    m.region_type,
    m.region,
    m.year_start,
    m.year_end,
    m.unit_original,
    CONCAT(m.source, ' | ', m.scenario_original) AS curve
FROM forecast_values v
JOIN forecast_metadata m
    ON v.forecast_id = m.forecast_id
ORDER BY 
    curve,
    v.year;
"""

with engine.connect() as conn:
    df = pd.read_sql(query, conn)


# ============================================================
# 4. Cleaning and filtering
# ============================================================

df["year"] = df["year"].astype(int)
df["demand_TWh"] = df["demand_TWh"].astype(float)

for col in [
    "source",
    "organization",
    "scenario_original",
    "scenario_standardized",
    "region_type",
    "region",
    "unit_original",
    "curve"
]:
    df[col] = df[col].astype(str).str.strip()

# Keep U.S. national-level forecasts only
df = df[
    (df["region_type"].str.lower() == "national")
    & (df["region"].str.upper() == "USA")
].copy()

# Remove old EIA AEO 2025 if EIA AEO 2026 is included.
# This keeps the ranking consistent with the range plots and heatmaps.
if "EIA_AEO2026" in set(df["source"]):
    df = df[df["source"] != "EIA"].copy()

# Normalize labels
df["source"] = df["source"].apply(normalize_source_name)
df["curve"] = df["source"] + " | " + df["scenario_original"]

# Scenario class
df["scenario_class"] = df.apply(classify_scenario, axis=1)

df = df.sort_values(by=["curve", "year"]).reset_index(drop=True)


# ============================================================
# 5. Generate ranking tables
# ============================================================

level_tables = {}
growth_tables = {}

for target_year in TARGET_YEARS:
    df_target = get_target_curve_values(df, target_year)

    if df_target.empty:
        print(f"No national curves cover {target_year}. Skipping.")
        continue

    level_table = representative_value_by_source(df_target, target_year)
    growth_table = growth_ranking_by_source(df, df_target, target_year)

    level_tables[target_year] = level_table
    growth_tables[target_year] = growth_table

    # Save CSV
    level_csv = os.path.join(
        OUTPUT_DIR,
        f"national_forecast_level_ranking_{target_year}.csv"
    )
    growth_csv = os.path.join(
        OUTPUT_DIR,
        f"national_growth_CAGR_ranking_to_{target_year}.csv"
    )

    level_table.to_csv(level_csv, index=False)
    growth_table.to_csv(growth_csv, index=False)

    print(f"\nNational target-year level ranking: {target_year}")
    print(level_table)

    print(f"\nNational growth / CAGR ranking to {target_year}")
    print(growth_table)


# ============================================================
# 6. Save Excel workbook
# ============================================================

with pd.ExcelWriter(OUTPUT_EXCEL, engine="openpyxl") as writer:
    for year, table in level_tables.items():
        table.to_excel(writer, sheet_name=f"level_{year}", index=False)

    for year, table in growth_tables.items():
        table.to_excel(writer, sheet_name=f"growth_{year}", index=False)

print("\nSaved national ranking tables:")
print(f"- Excel: {OUTPUT_EXCEL}")
print(f"- CSV files in folder: {OUTPUT_DIR}")