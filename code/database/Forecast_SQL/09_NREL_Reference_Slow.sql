-- ============================================
-- 09_NREL_Reference_Slow.sql
-- ============================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id FROM forecast_metadata
    WHERE source = 'NREL EFS'
    AND scenario_original = 'Reference_Slow'
);

DELETE FROM forecast_metadata
WHERE source = 'NREL EFS'
AND scenario_original = 'Reference_Slow';

INSERT INTO forecast_metadata (
    source, organization, scenario_original, scenario_standardized,
    region_type, region, year_start, year_end,
    unit_original, description
) VALUES (
    'NREL EFS',
    'National Renewable Energy Laboratory (EFS Study)',
    'Reference_Slow',
    'low',
    'national',
    'USA',
    2018,
    2050,
    'TWh',
    'Reference electrification – Slow advancement'
);

SET @fid = LAST_INSERT_ID();

-- Insert values
INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@fid, 2018, ROUND(3705.7008735114473, 2)),
(@fid, 2020, ROUND(3801.772339255354, 2)),
(@fid, 2024, ROUND(3897.772364494802, 2)),
(@fid, 2030, ROUND(4064.923333680291, 2)),
(@fid, 2040, ROUND(4400.762410451084, 2)),
(@fid, 2050, ROUND(4840.632385884002, 2));

COMMIT;