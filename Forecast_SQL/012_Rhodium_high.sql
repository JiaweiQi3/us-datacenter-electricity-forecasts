-- ============================================================
-- 012_Rhodium_high.sql
-- Source: Rhodium
-- Dataset: Analyst data center projections and Rhodium modeled growth pathways
-- Description: U.S. data center electricity demand forecast, high data center growth
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'Rhodium'
      AND scenario_original = 'High data center growth'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'Rhodium'
  AND scenario_original = 'High data center growth';


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
    'High data center growth',
    'high',
    'national',
    'USA',
    2022,
    2035,
    'TWh',
    'U.S. data center electricity demand forecast from Rhodium Group modeled high data center growth pathway.',
    'Values are digitized from Figure 1, Analyst data center projections (dots) and Rhodium modeled growth pathways (lines), in The impacts of rising electricity demand from data centers on US energy and emissions. Only Rhodium modeled line values are extracted. The high data center growth line represents Rhodium higher data center demand growth pathway. Analyst projection dots are not entered into this database table. Values should be interpreted as approximate digitized estimates.'
);

SET @RHODIUM_HIGH_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@RHODIUM_HIGH_ID, 2022, 151.55, NULL),
(@RHODIUM_HIGH_ID, 2023, 214.47, NULL),
(@RHODIUM_HIGH_ID, 2024, 277.39, NULL),
(@RHODIUM_HIGH_ID, 2025, 340.31, NULL),
(@RHODIUM_HIGH_ID, 2026, 403.23, NULL),
(@RHODIUM_HIGH_ID, 2027, 466.16, NULL),
(@RHODIUM_HIGH_ID, 2028, 529.08, NULL),
(@RHODIUM_HIGH_ID, 2029, 592.00, NULL),
(@RHODIUM_HIGH_ID, 2030, 654.92, NULL),
(@RHODIUM_HIGH_ID, 2031, 717.84, NULL),
(@RHODIUM_HIGH_ID, 2032, 780.76, NULL),
(@RHODIUM_HIGH_ID, 2033, 843.69, NULL),
(@RHODIUM_HIGH_ID, 2034, 906.61, NULL),
(@RHODIUM_HIGH_ID, 2035, 969.53, NULL);


COMMIT;