-- ============================================================
-- 002_LBNL_high.sql
-- Source: LBNL
-- Dataset: 2024 United States Data Center Energy Usage Report
-- Description: U.S. data center electricity demand forecast, high end of future scenario range
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'LBNL'
      AND scenario_original = 'Future scenario range - high end'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'LBNL'
  AND scenario_original = 'Future scenario range - high end';


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
    'Future scenario range - high end',
    'high',
    'national',
    'USA',
    2023,
    2028,
    'TWh',
    'U.S. data center electricity use forecast from the 2024 United States Data Center Energy Usage Report, high end of future scenario range.',
    'Values represent total U.S. data center electricity use including servers, storage, network equipment, and infrastructure. The 2023 value is reported in the report text as 176 TWh. The 2028 high endpoint is reported in the report text as roughly 580 TWh and 12.0% of total U.S. electricity consumption. Intermediate annual values for 2024-2027 are digitized from Figure ES-1 / Figure 5.5 and should be interpreted as approximate.'
);

SET @LBNL_HIGH_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@LBNL_HIGH_ID, 2023, 176.00, 4.40),
(@LBNL_HIGH_ID, 2024, 234.85, NULL),
(@LBNL_HIGH_ID, 2025, 309.38, NULL),
(@LBNL_HIGH_ID, 2026, 392.49, NULL),
(@LBNL_HIGH_ID, 2027, 485.79, NULL),
(@LBNL_HIGH_ID, 2028, 580.00, 12.00);


COMMIT;