-- ============================================================
-- 27_EIA_high_eco.sql
-- Source: EIA
-- Dataset: Annual Energy Outlook 2026
-- Scenario: High Economic Growth
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'EIA_AEO2026' AND scenario_original = 'High economic growth'
);

DELETE FROM forecast_metadata
WHERE source = 'EIA_AEO2026' AND scenario_original = 'High economic growth';

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
    'High economic growth',
    'high',
    'national',
    'USA',
    2025,
    2050,
    'billion kWh',
    'Higher GDP growth scenario leading to increased electricity demand'
);

SET @EIA_HIGH_ECON_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@EIA_HIGH_ECON_ID, 2025, 4299.47),
(@EIA_HIGH_ECON_ID, 2026, 4401.24),
(@EIA_HIGH_ECON_ID, 2027, 4421.07),
(@EIA_HIGH_ECON_ID, 2028, 4479.66),
(@EIA_HIGH_ECON_ID, 2029, 4538.37),
(@EIA_HIGH_ECON_ID, 2030, 4607.04),
(@EIA_HIGH_ECON_ID, 2031, 4675.38),
(@EIA_HIGH_ECON_ID, 2032, 4756.61),
(@EIA_HIGH_ECON_ID, 2033, 4850.57),
(@EIA_HIGH_ECON_ID, 2034, 4955.21),
(@EIA_HIGH_ECON_ID, 2035, 5065.78),
(@EIA_HIGH_ECON_ID, 2036, 5179.56),
(@EIA_HIGH_ECON_ID, 2037, 5290.78),
(@EIA_HIGH_ECON_ID, 2038, 5386.55),
(@EIA_HIGH_ECON_ID, 2039, 5483.73),
(@EIA_HIGH_ECON_ID, 2040, 5579.88),
(@EIA_HIGH_ECON_ID, 2041, 5670.30),
(@EIA_HIGH_ECON_ID, 2042, 5754.12),
(@EIA_HIGH_ECON_ID, 2043, 5832.36),
(@EIA_HIGH_ECON_ID, 2044, 5906.18),
(@EIA_HIGH_ECON_ID, 2045, 5982.56),
(@EIA_HIGH_ECON_ID, 2046, 6057.51),
(@EIA_HIGH_ECON_ID, 2047, 6131.88),
(@EIA_HIGH_ECON_ID, 2048, 6205.12),
(@EIA_HIGH_ECON_ID, 2049, 6272.65),
(@EIA_HIGH_ECON_ID, 2050, 6343.94);

COMMIT;