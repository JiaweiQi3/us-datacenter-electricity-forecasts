-- ============================================================
-- 001_LBNL_low.sql
-- Source: LBNL
-- Dataset: 2024 United States Data Center Energy Usage Report
-- Description: U.S. data center electricity demand forecast, low end of future scenario range
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'LBNL'
      AND scenario_original = 'Future scenario range - low end'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'LBNL'
  AND scenario_original = 'Future scenario range - low end';


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
    'LBNL',
    'Lawrence Berkeley National Laboratory',
    'Future scenario range - low end',
    'low',
    'national',
    'USA',
    2023,
    2028,
    'TWh',
    'U.S. data center electricity use forecast from the 2024 United States Data Center Energy Usage Report, low end of future scenario range.',
    'Values represent total U.S. data center electricity use including servers, storage, network equipment, and infrastructure. The 2023 value is reported in the report text as 176 TWh. The 2028 low endpoint is reported in the report text as roughly 325 TWh and 6.7% of total U.S. electricity consumption. Intermediate annual values for 2024-2027 are digitized from Figure ES-1 / Figure 5.5 and should be interpreted as approximate.'
);

SET @LBNL_LOW_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@LBNL_LOW_ID, 2023, 176.00, 4.40),
(@LBNL_LOW_ID, 2024, 180.16, NULL),
(@LBNL_LOW_ID, 2025, 197.86, NULL),
(@LBNL_LOW_ID, 2026, 234.32, NULL),
(@LBNL_LOW_ID, 2027, 275.07, NULL),
(@LBNL_LOW_ID, 2028, 325.00, 6.70);


COMMIT;