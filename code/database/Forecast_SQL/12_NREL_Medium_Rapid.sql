-- ============================================
-- 12_NREL_Medium_Rapid.sql
-- ============================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id FROM forecast_metadata
    WHERE source = 'NREL EFS'
    AND scenario_original = 'Medium_Rapid'
);

DELETE FROM forecast_metadata
WHERE source = 'NREL EFS'
AND scenario_original = 'Medium_Rapid';

INSERT INTO forecast_metadata (
    source, organization, scenario_original, scenario_standardized,
    region_type, region, year_start, year_end,
    unit_original, description
) VALUES (
    'NREL EFS',
    'National Renewable Energy Laboratory (EFS Study)',
    'Medium_Rapid',
    'mid',
    'national',
    'USA',
    2018,
    2050,
    'TWh',
    'Medium electrification – Rapid advancement'
);

SET @fid = LAST_INSERT_ID();

-- Insert values
INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@fid, 2018, ROUND(3707.701743790083, 2)),
(@fid, 2020, ROUND(3808.6658640736724, 2)),
(@fid, 2024, ROUND(3929.5743210141154, 2)),
(@fid, 2030, ROUND(4248.953816724069, 2)),
(@fid, 2040, ROUND(4969.961889559042, 2)),
(@fid, 2050, ROUND(5654.754158785039, 2));

COMMIT;