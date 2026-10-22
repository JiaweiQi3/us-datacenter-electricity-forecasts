-- ============================================
-- 11_NREL_Medium_Moderate.sql
-- ============================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id FROM forecast_metadata
    WHERE source = 'NREL EFS'
    AND scenario_original = 'Medium_Moderate'
);

DELETE FROM forecast_metadata
WHERE source = 'NREL EFS'
AND scenario_original = 'Medium_Moderate';

INSERT INTO forecast_metadata (
    source, organization, scenario_original, scenario_standardized,
    region_type, region, year_start, year_end,
    unit_original, description
) VALUES (
    'NREL EFS',
    'National Renewable Energy Laboratory (EFS Study)',
    'Medium_Moderate',
    'mid',
    'national',
    'USA',
    2018,
    2050,
    'TWh',
    'Medium electrification – Moderate advancement'
);

SET @fid = LAST_INSERT_ID();

-- Insert values
INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@fid, 2018, ROUND(3711.334117805869, 2)),
(@fid, 2020, ROUND(3814.3733727485474, 2)),
(@fid, 2024, ROUND(3942.2365864370086, 2)),
(@fid, 2030, ROUND(4284.744092135882, 2)),
(@fid, 2040, ROUND(5062.260716167445, 2)),
(@fid, 2050, ROUND(5798.91681256672, 2));

COMMIT;