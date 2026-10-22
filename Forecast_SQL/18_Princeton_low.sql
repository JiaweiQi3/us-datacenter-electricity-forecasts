-- ============================================================
-- 18_Princeton_low.sql
-- Source: Princeton
-- Dataset: Net-Zero America
-- Scenario: Low
-- ============================================================
USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'Princeton' AND scenario_standardized = 'low'
);

DELETE FROM forecast_metadata
WHERE source = 'Princeton' AND scenario_standardized = 'low';

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
    'Low scenario',
    'low',
    'national',
    'USA',
    2025,
    2050,
    'GWh (converted to TWh)',
    'Princeton electricity demand low scenario'
);

SET @PRINCETON_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@PRINCETON_ID, 2020, 4118.80),
(@PRINCETON_ID, 2025, 4198.02),
(@PRINCETON_ID, 2030, 4307.91),
(@PRINCETON_ID, 2035, 4527.23),
(@PRINCETON_ID, 2040, 4786.67),
(@PRINCETON_ID, 2045, 5031.42),
(@PRINCETON_ID, 2050, 5198.40);

COMMIT;