-- ============================================================
-- 30_EIA_low_supply.sql
-- Source: EIA
-- Dataset: Annual Energy Outlook 2026
-- Scenario: Low Oil and Gas Supply
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'EIA_AEO2026' AND scenario_original = 'Low oil and gas supply'
);

DELETE FROM forecast_metadata
WHERE source = 'EIA_AEO2026' AND scenario_original = 'Low oil and gas supply';

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
    'Low oil and gas supply',
    'low',
    'national',
    'USA',
    2025,
    2050,
    'billion kWh',
    'Lower oil and gas supply leads to higher energy prices and reduced electricity demand'
);

SET @EIA_LOW_OIL_SUPPLY_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@EIA_LOW_OIL_SUPPLY_ID, 2025, 4298.27),
(@EIA_LOW_OIL_SUPPLY_ID, 2026, 4367.35),
(@EIA_LOW_OIL_SUPPLY_ID, 2027, 4347.88),
(@EIA_LOW_OIL_SUPPLY_ID, 2028, 4364.69),
(@EIA_LOW_OIL_SUPPLY_ID, 2029, 4382.06),
(@EIA_LOW_OIL_SUPPLY_ID, 2030, 4415.41),
(@EIA_LOW_OIL_SUPPLY_ID, 2031, 4463.32),
(@EIA_LOW_OIL_SUPPLY_ID, 2032, 4524.06),
(@EIA_LOW_OIL_SUPPLY_ID, 2033, 4591.88),
(@EIA_LOW_OIL_SUPPLY_ID, 2034, 4678.11),
(@EIA_LOW_OIL_SUPPLY_ID, 2035, 4775.72),
(@EIA_LOW_OIL_SUPPLY_ID, 2036, 4879.58),
(@EIA_LOW_OIL_SUPPLY_ID, 2037, 4979.79),
(@EIA_LOW_OIL_SUPPLY_ID, 2038, 5069.76),
(@EIA_LOW_OIL_SUPPLY_ID, 2039, 5159.52),
(@EIA_LOW_OIL_SUPPLY_ID, 2040, 5235.98),
(@EIA_LOW_OIL_SUPPLY_ID, 2041, 5307.83),
(@EIA_LOW_OIL_SUPPLY_ID, 2042, 5370.64),
(@EIA_LOW_OIL_SUPPLY_ID, 2043, 5428.66),
(@EIA_LOW_OIL_SUPPLY_ID, 2044, 5484.69),
(@EIA_LOW_OIL_SUPPLY_ID, 2045, 5539.64),
(@EIA_LOW_OIL_SUPPLY_ID, 2046, 5593.03),
(@EIA_LOW_OIL_SUPPLY_ID, 2047, 5645.47),
(@EIA_LOW_OIL_SUPPLY_ID, 2048, 5696.39),
(@EIA_LOW_OIL_SUPPLY_ID, 2049, 5745.74),
(@EIA_LOW_OIL_SUPPLY_ID, 2050, 5794.70);

COMMIT;