-- ============================================================
-- 32_EIA_low_cost.sql
-- Source: EIA
-- Dataset: Annual Energy Outlook 2026
-- Scenario: Low Zero-Carbon Technology Cost
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'EIA_AEO2026' AND scenario_original = 'Low zero-carbon technology cost'
);

DELETE FROM forecast_metadata
WHERE source = 'EIA_AEO2026' AND scenario_original = 'Low zero-carbon technology cost';

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
    'Low zero-carbon technology cost',
    'high',
    'national',
    'USA',
    2025,
    2050,
    'billion kWh',
    'Lower zero-carbon technology costs accelerate electrification and increase electricity demand'
);

SET @EIA_LOW_ZC_COST_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@EIA_LOW_ZC_COST_ID, 2025, 4298.28),
(@EIA_LOW_ZC_COST_ID, 2026, 4386.09),
(@EIA_LOW_ZC_COST_ID, 2027, 4395.57),
(@EIA_LOW_ZC_COST_ID, 2028, 4446.66),
(@EIA_LOW_ZC_COST_ID, 2029, 4497.37),
(@EIA_LOW_ZC_COST_ID, 2030, 4549.88),
(@EIA_LOW_ZC_COST_ID, 2031, 4603.63),
(@EIA_LOW_ZC_COST_ID, 2032, 4668.60),
(@EIA_LOW_ZC_COST_ID, 2033, 4747.22),
(@EIA_LOW_ZC_COST_ID, 2034, 4844.17),
(@EIA_LOW_ZC_COST_ID, 2035, 4943.26),
(@EIA_LOW_ZC_COST_ID, 2036, 5043.00),
(@EIA_LOW_ZC_COST_ID, 2037, 5134.81),
(@EIA_LOW_ZC_COST_ID, 2038, 5216.56),
(@EIA_LOW_ZC_COST_ID, 2039, 5305.81),
(@EIA_LOW_ZC_COST_ID, 2040, 5389.01),
(@EIA_LOW_ZC_COST_ID, 2041, 5468.52),
(@EIA_LOW_ZC_COST_ID, 2042, 5543.31),
(@EIA_LOW_ZC_COST_ID, 2043, 5612.65),
(@EIA_LOW_ZC_COST_ID, 2044, 5677.44),
(@EIA_LOW_ZC_COST_ID, 2045, 5742.51),
(@EIA_LOW_ZC_COST_ID, 2046, 5804.37),
(@EIA_LOW_ZC_COST_ID, 2047, 5865.03),
(@EIA_LOW_ZC_COST_ID, 2048, 5922.12),
(@EIA_LOW_ZC_COST_ID, 2049, 5975.04),
(@EIA_LOW_ZC_COST_ID, 2050, 6024.97);

COMMIT;