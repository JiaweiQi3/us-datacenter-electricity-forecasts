-- ============================================================
-- 23_LCRI_high.sql
-- Source: LCRI
-- Dataset: LCRI Net-Zero 2050
-- Scenario: High
-- ============================================================
USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'LCRI' AND scenario_standardized = 'high'
);

DELETE FROM forecast_metadata
WHERE source = 'LCRI' AND scenario_standardized = 'high';

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
    'LCRI',
    'Low-Carbon Resources Initiative',
    'Upper bound scenario',
    'high',
    'national',
    'USA',
    2020,
    2050,
    'TWh',
    'Digitized from LCRI Net-Zero 2050 upper bound'
);

SET @LCRI_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@LCRI_ID, 2020, 4000.00),
(@LCRI_ID, 2025, 4342.61),
(@LCRI_ID, 2030, 5528.74),
(@LCRI_ID, 2035, 6816.92),
(@LCRI_ID, 2040, 7895.37),
(@LCRI_ID, 2045, 8896.14),
(@LCRI_ID, 2050, 9684.52);

COMMIT;