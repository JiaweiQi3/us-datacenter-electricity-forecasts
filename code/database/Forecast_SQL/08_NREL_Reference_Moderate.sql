-- ============================================
-- 08_NREL_Reference_Moderate.sql
-- ============================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id FROM forecast_metadata
    WHERE source = 'NREL EFS'
    AND scenario_original = 'Reference_Moderate'
);

DELETE FROM forecast_metadata
WHERE source = 'NREL EFS'
AND scenario_original = 'Reference_Moderate';

INSERT INTO forecast_metadata (
    source, organization, scenario_original, scenario_standardized,
    region_type, region, year_start, year_end,
    unit_original, description
) VALUES (
    'NREL EFS',
    'National Renewable Energy Laboratory (EFS Study)',
    'Reference_Moderate',
    'low',
    'national',
    'USA',
    2018,
    2050,
    'TWh',
    'Reference electrification – Moderate advancement'
);

SET @fid = LAST_INSERT_ID();

-- Insert values
INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@fid, 2018, ROUND(3704.6670563572393, 2)),
(@fid, 2020, ROUND(3799.123611133725, 2)),
(@fid, 2024, ROUND(3889.76342973582, 2)),
(@fid, 2030, ROUND(4043.933393059763, 2)),
(@fid, 2040, ROUND(4359.373231614207, 2)),
(@fid, 2050, ROUND(4787.898737523115, 2));

COMMIT;