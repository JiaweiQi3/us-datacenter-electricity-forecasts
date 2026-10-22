-- ============================================================
-- 20_Princeton_high.sql
-- Source: Princeton
-- Dataset: Net-Zero America
-- Scenario: High
-- ============================================================
USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'Princeton' AND scenario_standardized = 'high'
);

DELETE FROM forecast_metadata
WHERE source = 'Princeton' AND scenario_standardized = 'high';

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
    'High scenario',
    'high',
    'national',
    'USA',
    2025,
    2050,
    'GWh (converted to TWh)',
    'Princeton electricity demand high scenario'
);

SET @PRINCETON_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@PRINCETON_ID, 2020, 4122.79),
(@PRINCETON_ID, 2025, 4270.50),
(@PRINCETON_ID, 2030, 4627.71),
(@PRINCETON_ID, 2035, 5446.80),
(@PRINCETON_ID, 2040, 6334.63),
(@PRINCETON_ID, 2045, 7055.31),
(@PRINCETON_ID, 2050, 7453.98);

COMMIT;