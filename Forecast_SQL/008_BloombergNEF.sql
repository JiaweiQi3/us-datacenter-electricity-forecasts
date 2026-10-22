-- ============================================================
-- 008_BloombergNEF.sql
-- Source: BloombergNEF
-- Dataset: US data center power load forecast
-- Description: U.S. data center electricity demand forecast converted from projected power load
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM dc_forecast_values
WHERE dc_forecast_id IN (
    SELECT dc_forecast_id
    FROM dc_forecast_metadata
    WHERE source = 'BloombergNEF'
      AND scenario_original = 'Projected power load'
);

DELETE FROM dc_forecast_metadata
WHERE source = 'BloombergNEF'
  AND scenario_original = 'Projected power load';


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
    'BloombergNEF',
    'BloombergNEF',
    'Projected power load',
    'mid',
    'national',
    'USA',
    2024,
    2035,
    'GW',
    'U.S. data center electricity demand forecast converted from BloombergNEF / DC Byte projected data center power load.',
    'Values are digitized from Figure 1, US data center power load. The original figure reports projected data center power load in gigawatts. The digitized GW values were converted to annual electricity demand using TWh = GW * 8.76. The note below the figure states that power load and average power include the entire data center facility. Values should be interpreted as approximate digitized estimates.'
);

SET @BNEF_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO dc_forecast_values (
    dc_forecast_id,
    year,
    demand_TWh,
    share_percent
) VALUES
(@BNEF_ID, 2024, 303.43, NULL),
(@BNEF_ID, 2025, 365.18, NULL),
(@BNEF_ID, 2026, 419.80, NULL),
(@BNEF_ID, 2027, 463.73, NULL),
(@BNEF_ID, 2028, 505.29, NULL),
(@BNEF_ID, 2029, 539.72, NULL),
(@BNEF_ID, 2030, 570.59, NULL),
(@BNEF_ID, 2031, 600.28, NULL),
(@BNEF_ID, 2032, 627.59, NULL),
(@BNEF_ID, 2033, 648.96, NULL),
(@BNEF_ID, 2034, 667.96, NULL),
(@BNEF_ID, 2035, 683.40, NULL);


COMMIT;