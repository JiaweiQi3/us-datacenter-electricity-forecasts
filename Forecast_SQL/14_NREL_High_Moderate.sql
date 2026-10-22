-- ============================================
-- 14_NREL_High_Moderate.sql
-- ============================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id FROM forecast_metadata
    WHERE source = 'NREL EFS'
    AND scenario_original = 'High_Moderate'
);

DELETE FROM forecast_metadata
WHERE source = 'NREL EFS'
AND scenario_original = 'High_Moderate';

INSERT INTO forecast_metadata (
    source, organization, scenario_original, scenario_standardized,
    region_type, region, year_start, year_end,
    unit_original, description
) VALUES (
    'NREL EFS',
    'National Renewable Energy Laboratory (EFS Study)',
    'High_Moderate',
    'high',
    'national',
    'USA',
    2018,
    2050,
    'TWh',
    'High electrification – Moderate advancement'
);

SET @fid = LAST_INSERT_ID();

-- Insert values
INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@fid, 2018, ROUND(3707.6139143538126, 2)),
(@fid, 2020, ROUND(3809.290419988629, 2)),
(@fid, 2024, ROUND(3946.018619121949, 2)),
(@fid, 2030, ROUND(4367.355890098292, 2)),
(@fid, 2040, ROUND(5529.215513319958, 2)),
(@fid, 2050, ROUND(6699.035847896572, 2));

COMMIT;