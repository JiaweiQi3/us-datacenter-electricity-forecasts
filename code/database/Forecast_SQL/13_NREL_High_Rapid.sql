-- ============================================
-- 13_NREL_High_Rapid.sql
-- ============================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id FROM forecast_metadata
    WHERE source = 'NREL EFS'
    AND scenario_original = 'High_Rapid'
);

DELETE FROM forecast_metadata
WHERE source = 'NREL EFS'
AND scenario_original = 'High_Rapid';

INSERT INTO forecast_metadata (
    source, organization, scenario_original, scenario_standardized,
    region_type, region, year_start, year_end,
    unit_original, description
) VALUES (
    'NREL EFS',
    'National Renewable Energy Laboratory (EFS Study)',
    'High_Rapid',
    'high',
    'national',
    'USA',
    2018,
    2050,
    'TWh',
    'High electrification – Rapid advancement'
);

SET @fid = LAST_INSERT_ID();

-- Insert values
INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@fid, 2018, ROUND(3700.0632748327207, 2)),
(@fid, 2020, ROUND(3797.6152845225897, 2)),
(@fid, 2024, ROUND(3923.3677544575257, 2)),
(@fid, 2030, ROUND(4311.404750285126, 2)),
(@fid, 2040, ROUND(5380.060169044536, 2)),
(@fid, 2050, ROUND(6461.808236303815, 2));

COMMIT;