-- ============================================================
-- 21_LCRI_low.sql
-- Source: LCRI
-- Dataset: LCRI Net-Zero 2050
-- Scenario: Low
-- ============================================================
USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'LCRI' AND scenario_standardized = 'low'
);

DELETE FROM forecast_metadata
WHERE source = 'LCRI' AND scenario_standardized = 'low';

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
    'Lower bound scenario',
    'low',
    'national',
    'USA',
    2020,
    2050,
    'TWh',
    'Digitized from LCRI Net-Zero 2050 electricity demand lower bound'
);

SET @LCRI_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@LCRI_ID, 2020, 4000.00),
(@LCRI_ID, 2025, 4128.47),
(@LCRI_ID, 2030, 4386.92),
(@LCRI_ID, 2035, 4729.85),
(@LCRI_ID, 2040, 5098.64),
(@LCRI_ID, 2045, 5412.73),
(@LCRI_ID, 2050, 5718.26);

COMMIT;