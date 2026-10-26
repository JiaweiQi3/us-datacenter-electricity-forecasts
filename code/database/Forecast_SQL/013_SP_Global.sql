-- ============================================================
-- 013_SP_Global.sql
-- Source: S&P Global
-- Dataset: US datacenter and energy outlook
-- Description: U.S. data center electricity demand forecast, projected scenario
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'S&P Global'
      AND scenario_original = 'Projected'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'S&P Global'
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
    'S&P Global',
    'S&P Global Market Intelligence',
    'Projected',
    'mid',
    'national',
    'USA',
    2024,
    2028,
    'TWh',
    'U.S. data center electricity demand forecast from S&P Global Market Intelligence US datacenter and energy outlook.',
    'Values are digitized from the S&P curve in the comparison chart of U.S. data center electricity demand forecasts. The S&P Global source article is US datacenter and energy outlook - Powering the AI economy by Adam Wilson and Tony Lenoir, published June 13, 2024. The article states that annual electricity demand from U.S. datacenters is expected to reach over 280 TWh in 2024 and nearly double to 530 TWh by 2028. Digitized intermediate annual values should be interpreted as approximate estimates.'
);

SET @SP_GLOBAL_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@SP_GLOBAL_ID, 2024, 281.32, NULL),
(@SP_GLOBAL_ID, 2025, 345.15, NULL),
(@SP_GLOBAL_ID, 2026, 408.97, NULL),
(@SP_GLOBAL_ID, 2027, 472.80, NULL),
(@SP_GLOBAL_ID, 2028, 536.62, NULL);


COMMIT;