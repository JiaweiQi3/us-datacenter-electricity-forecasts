-- ============================================================
-- 003_EPRI_low.sql
-- Source: EPRI
-- Dataset: U.S. Data Center Electricity Demand Forecast
-- Description: U.S. data center electricity demand forecast, EPRI Low scenario
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'EPRI'
      AND scenario_original = 'EPRI Low'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'EPRI'
  AND scenario_original = 'EPRI Low';


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
    'EPRI Low',
    'low',
    'national',
    'USA',
    2024,
    2030,
    'TWh',
    'U.S. data center electricity demand forecast, EPRI Low scenario.',
    'Values are digitized from Figure ES-2, Comparison of U.S. data center annual electricity consumption projections. The extracted values correspond to the latest EPRI Low solid-line projection, not the dashed EPRI (2024) comparison line. Values should be interpreted as approximate digitized estimates.'
);

SET @EPRI_LOW_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@EPRI_LOW_ID, 2024, 180.48, NULL),
(@EPRI_LOW_ID, 2025, 208.85, NULL),
(@EPRI_LOW_ID, 2026, 251.11, NULL),
(@EPRI_LOW_ID, 2027, 297.59, NULL),
(@EPRI_LOW_ID, 2028, 332.60, NULL),
(@EPRI_LOW_ID, 2029, 358.55, NULL),
(@EPRI_LOW_ID, 2030, 383.90, NULL);


COMMIT;