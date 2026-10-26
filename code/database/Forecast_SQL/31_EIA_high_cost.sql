-- ============================================================
-- 31_EIA_high_cost.sql
-- Source: EIA
-- Dataset: Annual Energy Outlook 2026
-- Scenario: High Zero-Carbon Technology Cost
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'EIA_AEO2026' AND scenario_original = 'High zero-carbon technology cost'
);

DELETE FROM forecast_metadata
WHERE source = 'EIA_AEO2026' AND scenario_original = 'High zero-carbon technology cost';

-- ============================================================
-- 1. INSERT METADATA
-- ============================================================

INSERT INTO forecast_metadata (
    source,
    organization,
    scenario_original,
    scenario_standardized,
    region_type,
    region,
    year_start,
    year_end,
    unit_original,
    description
) VALUES (
    'EIA_AEO2026',
    'U.S. Energy Information Administration',
    'High zero-carbon technology cost',
    'low',
    'national',
    'USA',
    2025,
    2050,
    'billion kWh',
    'Higher zero-carbon technology costs slow electrification and reduce electricity demand'
);

SET @EIA_HIGH_ZC_COST_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@EIA_HIGH_ZC_COST_ID, 2025, 4298.28),
(@EIA_HIGH_ZC_COST_ID, 2026, 4385.42),
(@EIA_HIGH_ZC_COST_ID, 2027, 4395.37),
(@EIA_HIGH_ZC_COST_ID, 2028, 4447.29),
(@EIA_HIGH_ZC_COST_ID, 2029, 4495.95),
(@EIA_HIGH_ZC_COST_ID, 2030, 4547.10),
(@EIA_HIGH_ZC_COST_ID, 2031, 4601.47),
(@EIA_HIGH_ZC_COST_ID, 2032, 4666.66),
(@EIA_HIGH_ZC_COST_ID, 2033, 4742.98),
(@EIA_HIGH_ZC_COST_ID, 2034, 4834.32),
(@EIA_HIGH_ZC_COST_ID, 2035, 4928.76),
(@EIA_HIGH_ZC_COST_ID, 2036, 5025.56),
(@EIA_HIGH_ZC_COST_ID, 2037, 5120.90),
(@EIA_HIGH_ZC_COST_ID, 2038, 5197.50),
(@EIA_HIGH_ZC_COST_ID, 2039, 5284.13),
(@EIA_HIGH_ZC_COST_ID, 2040, 5364.22),
(@EIA_HIGH_ZC_COST_ID, 2041, 5441.53),
(@EIA_HIGH_ZC_COST_ID, 2042, 5515.32),
(@EIA_HIGH_ZC_COST_ID, 2043, 5583.16),
(@EIA_HIGH_ZC_COST_ID, 2044, 5646.18),
(@EIA_HIGH_ZC_COST_ID, 2045, 5710.05),
(@EIA_HIGH_ZC_COST_ID, 2046, 5772.23),
(@EIA_HIGH_ZC_COST_ID, 2047, 5831.34),
(@EIA_HIGH_ZC_COST_ID, 2048, 5887.22),
(@EIA_HIGH_ZC_COST_ID, 2049, 5939.77),
(@EIA_HIGH_ZC_COST_ID, 2050, 5990.95);

COMMIT;