-- ============================================================
-- 25_LBNL_high.sql
-- Source: LBNL
-- Dataset: United States Data Center Energy Usage Report
-- Scenario: High
-- ============================================================
USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'LBNL' AND scenario_standardized = 'high'
);

DELETE FROM forecast_metadata
WHERE source = 'LBNL' AND scenario_standardized = 'high';

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
    'LBNL',
    'Lawrence Berkeley National Laboratory',
    'High data center share scenario',
    'high',
    'national',
    'USA',
    2023,
    2028,
    'TWh (derived)',
    'Derived total electricity demand using LBNL high data center load and share'
);

SET @LBNL_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@LBNL_ID, 2023, 4000.00),
(@LBNL_ID, 2024, 3974.70),
(@LBNL_ID, 2025, 4121.31),
(@LBNL_ID, 2026, 4333.54),
(@LBNL_ID, 2027, 4574.39),
(@LBNL_ID, 2028, 4833.33);

COMMIT;