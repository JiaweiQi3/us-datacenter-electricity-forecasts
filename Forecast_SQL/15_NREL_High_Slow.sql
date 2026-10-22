-- ============================================
-- 15_NREL_High_Slow.sql
-- ============================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id FROM forecast_metadata
    WHERE source = 'NREL EFS'
    AND scenario_original = 'High_Slow'
);

DELETE FROM forecast_metadata
WHERE source = 'NREL EFS'
AND scenario_original = 'High_Slow';

INSERT INTO forecast_metadata (
    source, organization, scenario_original, scenario_standardized,
    region_type, region, year_start, year_end,
    unit_original, description
) VALUES (
    'NREL EFS',
    'National Renewable Energy Laboratory (EFS Study)',
    'High_Slow',
    'high',
    'national',
    'USA',
    2018,
    2050,
    'TWh',
    'High electrification – Slow advancement'
);

SET @fid = LAST_INSERT_ID();

-- Insert values
INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@fid, 2018, ROUND(3713.838198484585, 2)),
(@fid, 2020, ROUND(3823.4950617978957, 2)),
(@fid, 2024, ROUND(3980.043863938814, 2)),
(@fid, 2030, ROUND(4459.080848055667, 2)),
(@fid, 2040, ROUND(5767.4857185843775, 2)),
(@fid, 2050, ROUND(7062.432648548289, 2));

COMMIT;