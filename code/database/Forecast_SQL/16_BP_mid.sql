-- ============================================================
-- 16_BP_mid.sql
-- Source: BP
-- Dataset: Energy Outlook 2025 – US insights
-- Scenario: Current Trajectory
-- Description: US electricity demand (power generation, TWh)
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'BP' AND scenario_original = 'Current Trajectory'
);

DELETE FROM forecast_metadata
WHERE source = 'BP' AND scenario_original = 'Current Trajectory';


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
    'BP',
    'British Petroleum',
    'Current Trajectory',
    'mid',
    'national',
    'USA',
    2023,
    2050,
    'TWh (power generation)',
    'BP Energy Outlook 2025 US insights; electricity demand (power generation) for Current Trajectory scenario'
);

SET @BP_CT_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@BP_CT_ID, 2023, 4440),
(@BP_CT_ID, 2050, 7902);


COMMIT;