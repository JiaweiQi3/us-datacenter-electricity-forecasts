-- ============================================================
-- 010_IEA.sql
-- Source: IEA
-- Dataset: Data center electricity consumption by region
-- Description: U.S. data center electricity demand forecast, projected scenario
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'IEA'
      AND scenario_original = 'Projected'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'IEA'
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
    'IEA',
    'International Energy Agency',
    'Projected',
    'mid',
    'national',
    'USA',
    2024,
    2030,
    'TWh',
    'U.S. data center electricity demand forecast digitized from IEA regional data center electricity consumption chart.',
    'Values are digitized from the IEA chart showing data center electricity consumption by region. Only the United States layer is extracted. The original unit is TWh, so no unit conversion is applied. Values should be interpreted as approximate digitized estimates.'
);

SET @IEA_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@IEA_ID, 2024, 182.68, NULL),
(@IEA_ID, 2025, 225.20, NULL),
(@IEA_ID, 2026, 258.27, NULL),
(@IEA_ID, 2027, 303.94, NULL),
(@IEA_ID, 2028, 349.61, NULL),
(@IEA_ID, 2029, 390.55, NULL),
(@IEA_ID, 2030, 423.62, NULL);


COMMIT;