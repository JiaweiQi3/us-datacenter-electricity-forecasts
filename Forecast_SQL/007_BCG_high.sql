-- ============================================================
-- 007_BCG_high.sql
-- Source: BCG
-- Dataset: Projected annual US data center power demand
-- Description: U.S. data center electricity demand forecast, BCG high-demand case
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'BCG'
      AND scenario_original = 'High-demand case'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'BCG'
  AND scenario_original = 'High-demand case';


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
    'BCG',
    'Boston Consulting Group',
    'High-demand case',
    'high',
    'national',
    'USA',
    2024,
    2030,
    'TWh',
    'U.S. data center electricity demand forecast from BCG Exhibit 1, high-demand case.',
    'Values are extracted from the labeled high-demand case range in BCG Exhibit 1, Projected annual US data center power demand. The high-demand case corresponds to the upper value shown above the dashed extension for each year. Sector breakdown values for hyperscaler, colocation provider, and enterprise are not entered into this database table.'
);

SET @BCG_HIGH_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@BCG_HIGH_ID, 2024, 325.00, NULL),
(@BCG_HIGH_ID, 2025, 400.00, NULL),
(@BCG_HIGH_ID, 2026, 475.00, NULL),
(@BCG_HIGH_ID, 2027, 575.00, NULL),
(@BCG_HIGH_ID, 2028, 700.00, NULL),
(@BCG_HIGH_ID, 2029, 850.00, NULL),
(@BCG_HIGH_ID, 2030, 1050.00, NULL);


COMMIT;