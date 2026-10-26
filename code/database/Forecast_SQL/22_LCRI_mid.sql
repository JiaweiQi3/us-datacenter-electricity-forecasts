-- ============================================================
-- 22_LCRI_mid.sql
-- Source: LCRI
-- Dataset: LCRI Net-Zero 2050
-- Scenario: Mid
-- ============================================================
USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'LCRI' AND scenario_standardized = 'mid'
);

DELETE FROM forecast_metadata
WHERE source = 'LCRI' AND scenario_standardized = 'mid';

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
    'Central trajectory (dashed line)',
    'mid',
    'national',
    'USA',
    2020,
    2050,
    'TWh',
    'Digitized from LCRI Net-Zero 2050 mid trajectory'
);

SET @LCRI_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@LCRI_ID, 2020, 4000.00),
(@LCRI_ID, 2025, 4216.38),
(@LCRI_ID, 2030, 4827.55),
(@LCRI_ID, 2035, 5568.14),
(@LCRI_ID, 2040, 6306.92),
(@LCRI_ID, 2045, 6842.77),
(@LCRI_ID, 2050, 7136.48);

COMMIT;