-- ============================================
-- 02_IEA.sql
-- Source: IEA (derived from per capita + growth rates)
-- ============================================
USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'IEA'
);

DELETE FROM forecast_metadata
WHERE source = 'IEA';


-- ============================================
-- 1. INSERT METADATA
-- ============================================

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
    'IEA',
    'International Energy Agency',
    'Derived from per capita + YoY growth',
    'mid',
    'national',
    'USA',
    2024,
    2030,
    'MWh/capita + % growth',
    'Constructed forecast using IEA per capita electricity consumption (2024) and projected growth rates (2025–2030), combined with U.S. population data'
);

SET @IEA_ID = LAST_INSERT_ID();


-- ============================================
-- 2. INSERT VALUES
-- ============================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@IEA_ID, 2024, 4250.00),
(@IEA_ID, 2025, 4377.50),
(@IEA_ID, 2026, 4465.05),
(@IEA_ID, 2027, 4554.35),
(@IEA_ID, 2028, 4690.98),
(@IEA_ID, 2029, 4784.80),
(@IEA_ID, 2030, 4880.50);


COMMIT;