-- ============================================================
-- 33_EIA_high_demand.sql
-- Source: EIA
-- Dataset: Annual Energy Outlook 2026
-- Scenario: High Electricity Demand
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'EIA_AEO2026' AND scenario_original = 'High electricity demand'
);

DELETE FROM forecast_metadata
WHERE source = 'EIA_AEO2026' AND scenario_original = 'High electricity demand';

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
    'High electricity demand',
    'high',
    'national',
    'USA',
    2025,
    2050,
    'billion kWh',
    'High end-use electrification scenario resulting in significantly higher electricity demand'
);

SET @EIA_HIGH_DEMAND_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@EIA_HIGH_DEMAND_ID, 2025, 4298.28),
(@EIA_HIGH_DEMAND_ID, 2026, 4422.91),
(@EIA_HIGH_DEMAND_ID, 2027, 4426.68),
(@EIA_HIGH_DEMAND_ID, 2028, 4474.19),
(@EIA_HIGH_DEMAND_ID, 2029, 4522.59),
(@EIA_HIGH_DEMAND_ID, 2030, 4572.97),
(@EIA_HIGH_DEMAND_ID, 2031, 4634.35),
(@EIA_HIGH_DEMAND_ID, 2032, 4708.82),
(@EIA_HIGH_DEMAND_ID, 2033, 4796.43),
(@EIA_HIGH_DEMAND_ID, 2034, 4904.39),
(@EIA_HIGH_DEMAND_ID, 2035, 5018.20),
(@EIA_HIGH_DEMAND_ID, 2036, 5135.32),
(@EIA_HIGH_DEMAND_ID, 2037, 5241.95),
(@EIA_HIGH_DEMAND_ID, 2038, 5335.61),
(@EIA_HIGH_DEMAND_ID, 2039, 5441.20),
(@EIA_HIGH_DEMAND_ID, 2040, 5541.53),
(@EIA_HIGH_DEMAND_ID, 2041, 5639.75),
(@EIA_HIGH_DEMAND_ID, 2042, 5736.50),
(@EIA_HIGH_DEMAND_ID, 2043, 5828.60),
(@EIA_HIGH_DEMAND_ID, 2044, 5918.19),
(@EIA_HIGH_DEMAND_ID, 2045, 6010.84),
(@EIA_HIGH_DEMAND_ID, 2046, 6104.35),
(@EIA_HIGH_DEMAND_ID, 2047, 6197.63),
(@EIA_HIGH_DEMAND_ID, 2048, 6288.53),
(@EIA_HIGH_DEMAND_ID, 2049, 6379.06),
(@EIA_HIGH_DEMAND_ID, 2050, 6469.61);

COMMIT;