-- ============================================================
-- 014_Jefferies.sql
-- Source: Jefferies
-- Dataset: How Data Centers Are Shaping the Future of Energy Consumption
-- Description: U.S. data center electricity demand forecast, projected scenario
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'Jefferies'
      AND scenario_original = 'Projected'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'Jefferies'
  AND scenario_original = 'Projected';


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
    'Jefferies',
    'Jefferies',
    'Projected',
    'mid',
    'national',
    'USA',
    2024,
    2030,
    'TWh',
    'U.S. data center electricity demand forecast from Jefferies projected scenario.',
    'Values are digitized from the Jefferies curve in the WRI comparison chart of U.S. data center electricity demand forecasts. The curve is shown as a teal dashed line labeled Jeffries/Jefferies. The Jefferies source page is How Data Centers Are Shaping the Future of Energy Consumption, published June 26, 2024, which summarizes Jefferies Equity Research Team report Powering Data Centers and notes Jefferies projects U.S. data center electricity consumption growth through 2030. Values should be interpreted as approximate digitized estimates and are based on the comparison chart rather than an original Jefferies data table.'
);

SET @JEFFERIES_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@JEFFERIES_ID, 2024, 251.32, NULL),
(@JEFFERIES_ID, 2025, 287.04, NULL),
(@JEFFERIES_ID, 2026, 333.99, NULL),
(@JEFFERIES_ID, 2027, 382.28, NULL),
(@JEFFERIES_ID, 2028, 437.83, NULL),
(@JEFFERIES_ID, 2029, 476.19, NULL),
(@JEFFERIES_ID, 2030, 525.13, NULL);


COMMIT;