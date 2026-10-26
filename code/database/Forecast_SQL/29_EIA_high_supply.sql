-- ============================================================
-- 29_EIA_high_supply.sql
-- Source: EIA
-- Dataset: Annual Energy Outlook 2026
-- Scenario: High Oil and Gas Supply
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'EIA_AEO2026' AND scenario_original = 'High oil and gas supply'
);

DELETE FROM forecast_metadata
WHERE source = 'EIA_AEO2026' AND scenario_original = 'High oil and gas supply';

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
    'High oil and gas supply',
    'high',
    'national',
    'USA',
    2025,
    2050,
    'billion kWh',
    'Higher oil and gas supply leads to lower energy prices and higher electricity demand'
);

SET @EIA_HIGH_OIL_SUPPLY_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@EIA_HIGH_OIL_SUPPLY_ID, 2025, 4298.27),
(@EIA_HIGH_OIL_SUPPLY_ID, 2026, 4401.16),
(@EIA_HIGH_OIL_SUPPLY_ID, 2027, 4419.66),
(@EIA_HIGH_OIL_SUPPLY_ID, 2028, 4475.12),
(@EIA_HIGH_OIL_SUPPLY_ID, 2029, 4531.79),
(@EIA_HIGH_OIL_SUPPLY_ID, 2030, 4593.09),
(@EIA_HIGH_OIL_SUPPLY_ID, 2031, 4650.99),
(@EIA_HIGH_OIL_SUPPLY_ID, 2032, 4726.52),
(@EIA_HIGH_OIL_SUPPLY_ID, 2033, 4805.84),
(@EIA_HIGH_OIL_SUPPLY_ID, 2034, 4895.94),
(@EIA_HIGH_OIL_SUPPLY_ID, 2035, 4988.39),
(@EIA_HIGH_OIL_SUPPLY_ID, 2036, 5083.26),
(@EIA_HIGH_OIL_SUPPLY_ID, 2037, 5178.45),
(@EIA_HIGH_OIL_SUPPLY_ID, 2038, 5263.21),
(@EIA_HIGH_OIL_SUPPLY_ID, 2039, 5356.45),
(@EIA_HIGH_OIL_SUPPLY_ID, 2040, 5444.87),
(@EIA_HIGH_OIL_SUPPLY_ID, 2041, 5528.31),
(@EIA_HIGH_OIL_SUPPLY_ID, 2042, 5608.78),
(@EIA_HIGH_OIL_SUPPLY_ID, 2043, 5683.98),
(@EIA_HIGH_OIL_SUPPLY_ID, 2044, 5750.46),
(@EIA_HIGH_OIL_SUPPLY_ID, 2045, 5815.93),
(@EIA_HIGH_OIL_SUPPLY_ID, 2046, 5880.04),
(@EIA_HIGH_OIL_SUPPLY_ID, 2047, 5942.19),
(@EIA_HIGH_OIL_SUPPLY_ID, 2048, 5998.69),
(@EIA_HIGH_OIL_SUPPLY_ID, 2049, 6052.19),
(@EIA_HIGH_OIL_SUPPLY_ID, 2050, 6104.43);

COMMIT;