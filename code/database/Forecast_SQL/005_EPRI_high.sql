-- ============================================================
-- 005_EPRI_high.sql
-- Source: EPRI
-- Dataset: U.S. Data Center Electricity Demand Forecast
-- Description: U.S. data center electricity demand forecast, EPRI High scenario
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'EPRI'
      AND scenario_original = 'EPRI High'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'EPRI'
  AND scenario_original = 'EPRI High';


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
    'EPRI',
    'Electric Power Research Institute',
    'EPRI High',
    'high',
    'national',
    'USA',
    2024,
    2030,
    'TWh',
    'U.S. data center electricity demand forecast, EPRI High scenario.',
    'Values are digitized from Figure ES-2, Comparison of U.S. data center annual electricity consumption projections. The extracted values correspond to the latest EPRI High solid-line projection, not the dashed EPRI (2024) comparison line. Values should be interpreted as approximate digitized estimates.'
);

SET @EPRI_HIGH_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@EPRI_HIGH_ID, 2024, 197.99, NULL),
(@EPRI_HIGH_ID, 2025, 259.56, NULL),
(@EPRI_HIGH_ID, 2026, 350.10, NULL),
(@EPRI_HIGH_ID, 2027, 459.36, NULL),
(@EPRI_HIGH_ID, 2028, 578.27, NULL),
(@EPRI_HIGH_ID, 2029, 686.92, NULL),
(@EPRI_HIGH_ID, 2030, 790.74, NULL);


COMMIT;