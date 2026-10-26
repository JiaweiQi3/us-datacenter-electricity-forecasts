-- ============================================================
-- 009_McKinsey.sql
-- Source: McKinsey
-- Dataset: Projected US data center energy consumption
-- Description: U.S. data center electricity demand forecast, medium scenario
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'McKinsey'
      AND scenario_original = 'Medium scenario'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'McKinsey'
  AND scenario_original = 'Medium scenario';


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
    'McKinsey',
    'McKinsey & Company',
    'Medium scenario',
    'mid',
    'national',
    'USA',
    2023,
    2030,
    'TWh',
    'U.S. data center electricity demand forecast from McKinsey projected US data center energy consumption, medium scenario.',
    'Values are extracted from McKinsey figure titled Projected US data center energy consumption (medium scenario), terawatt-hours. Demand_TWh values are digitized from the left-side area chart. Share_percent values are taken from the labeled right-side chart, Projected US data center share of total US power demand. Values should be interpreted as approximate digitized estimates. Source note in figure: Global Energy Perspective 2023, McKinsey, Oct 18, 2023; McKinsey analysis.'
);

SET @MCKINSEY_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@MCKINSEY_ID, 2023, 147.61, 3.70),
(@MCKINSEY_ID, 2024, 179.18, 4.30),
(@MCKINSEY_ID, 2025, 226.53, 5.20),
(@MCKINSEY_ID, 2026, 295.23, 6.50),
(@MCKINSEY_ID, 2027, 373.21, 8.00),
(@MCKINSEY_ID, 2028, 452.12, 9.30),
(@MCKINSEY_ID, 2029, 516.18, 10.30),
(@MCKINSEY_ID, 2030, 604.38, 11.70);


COMMIT;