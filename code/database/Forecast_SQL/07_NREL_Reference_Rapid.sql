-- ============================================
-- 07_NREL_Reference_Rapid.sql
-- ============================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id FROM forecast_metadata
    WHERE source = 'NREL EFS'
    AND scenario_original = 'Reference_Rapid'
);

DELETE FROM forecast_metadata
WHERE source = 'NREL EFS'
AND scenario_original = 'Reference_Rapid';

INSERT INTO forecast_metadata (
    source, organization, scenario_original, scenario_standardized,
    region_type, region, year_start, year_end,
    unit_original, description
) VALUES (
    'NREL EFS',
    'National Renewable Energy Laboratory (EFS Study)',
    'Reference_Rapid',
    'low',
    'national',
    'USA',
    2018,
    2050,
    'TWh',
    'Reference electrification – Rapid advancement'
);

SET @fid = LAST_INSERT_ID();

-- Insert values
INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@fid, 2018, ROUND(3701.6621662106368, 2)),
(@fid, 2020, ROUND(3795.0395026155134, 2)),
(@fid, 2024, ROUND(3882.683883949313, 2)),
(@fid, 2030, ROUND(4030.947797505082, 2)),
(@fid, 2040, ROUND(4337.616161035882, 2)),
(@fid, 2050, ROUND(4760.362814014378, 2));

COMMIT;