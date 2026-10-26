-- ============================================================
-- 28_EIA_low_eco.sql
-- Source: EIA
-- Dataset: Annual Energy Outlook 2026
-- Scenario: Low Economic Growth
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'EIA_AEO2026' AND scenario_original = 'Low economic growth'
);

DELETE FROM forecast_metadata
WHERE source = 'EIA_AEO2026' AND scenario_original = 'Low economic growth';

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
    'Low economic growth',
    'low',
    'national',
    'USA',
    2025,
    2050,
    'billion kWh',
    'Lower GDP growth scenario leading to reduced electricity demand'
);

SET @EIA_LOW_ECON_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@EIA_LOW_ECON_ID, 2025, 4296.99),
(@EIA_LOW_ECON_ID, 2026, 4359.51),
(@EIA_LOW_ECON_ID, 2027, 4344.70),
(@EIA_LOW_ECON_ID, 2028, 4386.51),
(@EIA_LOW_ECON_ID, 2029, 4423.54),
(@EIA_LOW_ECON_ID, 2030, 4459.83),
(@EIA_LOW_ECON_ID, 2031, 4499.46),
(@EIA_LOW_ECON_ID, 2032, 4554.33),
(@EIA_LOW_ECON_ID, 2033, 4620.39),
(@EIA_LOW_ECON_ID, 2034, 4696.52),
(@EIA_LOW_ECON_ID, 2035, 4779.96),
(@EIA_LOW_ECON_ID, 2036, 4861.88),
(@EIA_LOW_ECON_ID, 2037, 4939.96),
(@EIA_LOW_ECON_ID, 2038, 5008.09),
(@EIA_LOW_ECON_ID, 2039, 5083.62),
(@EIA_LOW_ECON_ID, 2040, 5156.60),
(@EIA_LOW_ECON_ID, 2041, 5226.18),
(@EIA_LOW_ECON_ID, 2042, 5292.92),
(@EIA_LOW_ECON_ID, 2043, 5352.05),
(@EIA_LOW_ECON_ID, 2044, 5405.20),
(@EIA_LOW_ECON_ID, 2045, 5456.81),
(@EIA_LOW_ECON_ID, 2046, 5505.53),
(@EIA_LOW_ECON_ID, 2047, 5552.91),
(@EIA_LOW_ECON_ID, 2048, 5596.25),
(@EIA_LOW_ECON_ID, 2049, 5636.60),
(@EIA_LOW_ECON_ID, 2050, 5677.58);

COMMIT;