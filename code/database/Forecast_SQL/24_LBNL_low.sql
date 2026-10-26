-- ============================================================
-- 24_LBNL_low.sql
-- Source: LBNL
-- Dataset: United States Data Center Energy Usage Report
-- Scenario: Low
-- ============================================================
USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'LBNL' AND scenario_standardized = 'low'
);

DELETE FROM forecast_metadata
WHERE source = 'LBNL' AND scenario_standardized = 'low';

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
    'Low data center share scenario',
    'low',
    'national',
    'USA',
    2023,
    2028,
    'TWh (derived)',
    'Derived total electricity demand using LBNL low data center load and share'
);

SET @LBNL_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@LBNL_ID, 2023, 4000.00),
(@LBNL_ID, 2024, 3746.54),
(@LBNL_ID, 2025, 3746.36),
(@LBNL_ID, 2026, 3921.86),
(@LBNL_ID, 2027, 4396.15),
(@LBNL_ID, 2028, 4850.75);

COMMIT;