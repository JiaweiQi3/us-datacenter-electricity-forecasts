-- ============================================================
-- 006_BCG_low.sql
-- Source: BCG
-- Dataset: Projected annual US data center power demand
-- Description: U.S. data center electricity demand forecast, BCG lower/base case
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'BCG'
      AND scenario_original = 'Lower/base case'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'BCG'
  AND scenario_original = 'Lower/base case';


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
    'Lower/base case',
    'low',
    'national',
    'USA',
    2024,
    2030,
    'TWh',
    'U.S. data center electricity demand forecast from BCG Exhibit 1, lower/base case.',
    'Values are extracted from the labeled totals in BCG Exhibit 1, Projected annual US data center power demand. The lower/base case corresponds to the solid stacked bar total, excluding the dashed high-demand case extension. Sector breakdown values for hyperscaler, colocation provider, and enterprise are not entered into this database table.'
);

SET @BCG_LOW_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@BCG_LOW_ID, 2024, 325.00, NULL),
(@BCG_LOW_ID, 2025, 350.00, NULL),
(@BCG_LOW_ID, 2026, 425.00, NULL),
(@BCG_LOW_ID, 2027, 500.00, NULL),
(@BCG_LOW_ID, 2028, 625.00, NULL),
(@BCG_LOW_ID, 2029, 725.00, NULL),
(@BCG_LOW_ID, 2030, 800.00, NULL);


COMMIT;