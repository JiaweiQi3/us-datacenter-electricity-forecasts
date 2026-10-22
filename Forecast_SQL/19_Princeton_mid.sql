-- ============================================================
-- 19_Princeton_mid.sql
-- Source: Princeton
-- Dataset: Net-Zero America
-- Scenario: Mid
-- ============================================================
USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'Princeton' AND scenario_standardized = 'mid'
);

DELETE FROM forecast_metadata
WHERE source = 'Princeton' AND scenario_standardized = 'mid';

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
    'Princeton',
    'Princeton Net-Zero America Project',
    'Mid scenario',
    'mid',
    'national',
    'USA',
    2025,
    2050,
    'GWh (converted to TWh)',
    'Princeton electricity demand mid scenario'
);

SET @PRINCETON_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@PRINCETON_ID, 2020, 4122.63),
(@PRINCETON_ID, 2025, 4248.00),
(@PRINCETON_ID, 2030, 4428.29),
(@PRINCETON_ID, 2035, 4627.51),
(@PRINCETON_ID, 2040, 4890.90),
(@PRINCETON_ID, 2045, 5532.29),
(@PRINCETON_ID, 2050, 6192.41);

COMMIT;