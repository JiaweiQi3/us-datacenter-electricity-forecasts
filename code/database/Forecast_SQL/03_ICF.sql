-- ============================================================
-- 03_ICF.sql
-- Source: ICF (Derived from EIA baseline)
-- Dataset: Electricity demand based on ICF growth rates
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'ICF'
);

DELETE FROM forecast_metadata
WHERE source = 'ICF';


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
    'ICF',
    'ICF International',
    'Growth-based estimate',
    'mid',
    'national',
    'USA',
    2023,
    2050,
    'TWh (derived from EIA 2023 baseline)',
    'Absolute electricity demand derived using EIA 2023 (4048.7 TWh) baseline and ICF growth rates (+25% by 2030, +78% by 2050)'
);

SET @ICF_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@ICF_ID, 2023, 4048.7),
(@ICF_ID, 2030, 5060.9),
(@ICF_ID, 2050, 7206.7);


COMMIT;