-- ============================================
-- 05_SP_Global_low.sql
-- Source: S&P Global
-- ============================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

-- Clean ONLY low scenario
DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id FROM forecast_metadata
    WHERE source = 'S&P Global'
    AND scenario_standardized = 'low'
);

DELETE FROM forecast_metadata
WHERE source = 'S&P Global'
AND scenario_standardized = 'low';

-- Insert metadata
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
    'S&P Global',
    'S&P Global Commodity Insights',
    'Outlook range (lower bound)',
    'low',
    'national',
    'USA',
    2024,
    2040,
    'TWh',
    'Lower bound of US electricity demand forecast from S&P Global report (Lower 48 net on-grid electricity demand)'
);

SET @fid = LAST_INSERT_ID();

-- Insert values
INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@fid, 2024, 4170),
(@fid, 2030, 4734),
(@fid, 2035, 5139),
(@fid, 2040, 5591);

COMMIT;