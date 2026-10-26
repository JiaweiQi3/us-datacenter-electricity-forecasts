-- ============================================================
-- 04_Citi.sql
-- Source: Citi
-- Dataset: Citi Research Power Demand Outlook
-- Scenario: Mid (2.8% CAGR)
-- ============================================================
USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'Citi' AND scenario_standardized = 'mid'
);

DELETE FROM forecast_metadata
WHERE source = 'Citi' AND scenario_standardized = 'mid';

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
    'Citi',
    'Citigroup',
    '2.8% CAGR',
    'mid',
    'national',
    'USA',
    2025,
    2040,
    'TWh',
    'Constructed from Citi Research 2.8% annual growth rate using EIA 2025 baseline'
);

SET @CITI_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@CITI_ID, 2025, 4219.155),
(@CITI_ID, 2026, 4337.291),
(@CITI_ID, 2027, 4458.735),
(@CITI_ID, 2028, 4583.580),
(@CITI_ID, 2029, 4711.921),
(@CITI_ID, 2030, 4843.855),
(@CITI_ID, 2031, 4979.483),
(@CITI_ID, 2032, 5118.908),
(@CITI_ID, 2033, 5262.236),
(@CITI_ID, 2034, 5409.579),
(@CITI_ID, 2035, 5561.048),
(@CITI_ID, 2036, 5716.757),
(@CITI_ID, 2037, 5876.826),
(@CITI_ID, 2038, 6041.377),
(@CITI_ID, 2039, 6210.536),
(@CITI_ID, 2040, 6384.430);

COMMIT;