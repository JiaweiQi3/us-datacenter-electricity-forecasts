-- ============================================================
-- 011_Rhodium_low.sql
-- Source: Rhodium
-- Dataset: Analyst data center projections and Rhodium modeled growth pathways
-- Description: U.S. data center electricity demand forecast, baseline data center growth
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'Rhodium'
      AND scenario_original = 'Baseline data center growth'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'Rhodium'
  AND scenario_original = 'Baseline data center growth';


-- ============================================================
-- 1. INSERT METADATA
-- ============================================================

INSERT INTO dc_forecast_metadata (
    source,
    organization,
    scenario_original,
    scenario_standardized,
    region_type,
    region,
    year_start,
    year_end,
    unit_original,
    description,
    notes
) VALUES (
    'Rhodium',
    'Rhodium Group',
    'Baseline data center growth',
    'low',
    'national',
    'USA',
    2022,
    2035,
    'TWh',
    'U.S. data center electricity demand forecast from Rhodium Group modeled baseline data center growth pathway.',
    'Values are digitized from Figure 1, Analyst data center projections (dots) and Rhodium modeled growth pathways (lines), in The impacts of rising electricity demand from data centers on US energy and emissions. Only Rhodium modeled line values are extracted. The baseline data center growth line represents the lower of Rhodium two modeled data center demand growth pathways. Analyst projection dots are not entered into this database table. Values should be interpreted as approximate digitized estimates.'
);

SET @RHODIUM_BASELINE_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@RHODIUM_BASELINE_ID, 2022, 151.52, NULL),
(@RHODIUM_BASELINE_ID, 2023, 187.13, NULL),
(@RHODIUM_BASELINE_ID, 2024, 222.73, NULL),
(@RHODIUM_BASELINE_ID, 2025, 258.34, NULL),
(@RHODIUM_BASELINE_ID, 2026, 293.94, NULL),
(@RHODIUM_BASELINE_ID, 2027, 329.55, NULL),
(@RHODIUM_BASELINE_ID, 2028, 365.15, NULL),
(@RHODIUM_BASELINE_ID, 2029, 400.76, NULL),
(@RHODIUM_BASELINE_ID, 2030, 436.36, NULL),
(@RHODIUM_BASELINE_ID, 2031, 471.97, NULL),
(@RHODIUM_BASELINE_ID, 2032, 507.57, NULL),
(@RHODIUM_BASELINE_ID, 2033, 543.18, NULL),
(@RHODIUM_BASELINE_ID, 2034, 578.78, NULL),
(@RHODIUM_BASELINE_ID, 2035, 614.39, NULL);


COMMIT;