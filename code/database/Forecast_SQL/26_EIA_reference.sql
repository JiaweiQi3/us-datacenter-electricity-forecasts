-- ============================================================
-- 26_EIA_reference.sql
-- Source: EIA
-- Dataset: Annual Energy Outlook 2026
-- Scenario: Reference (Counterfactual Baseline)
-- ============================================================

USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'EIA_AEO2026' AND scenario_standardized = 'mid'
);

DELETE FROM forecast_metadata
WHERE source = 'EIA_AEO2026' AND scenario_standardized = 'mid';

-- ============================================================
-- 1. INSERT METADATA
-- ============================================================

INSERT INTO forecast_metadata (
    source,
    organization,
    scenario_original,
    scenario_standardized,
    region_type,
    region,
    year_start,
    year_end,
    unit_original,
    description
) VALUES (
    'EIA_AEO2026',
    'U.S. Energy Information Administration',
    'Counterfactual Baseline case',
    'mid',
    'national',
    'USA',
    2025,
    2050,
    'billion kWh',
    'AEO 2026 counterfactual baseline case (reference scenario)'
);

SET @EIA_REF_ID = LAST_INSERT_ID();

-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@EIA_REF_ID, 2025, 4298.27),
(@EIA_REF_ID, 2026, 4422.88),
(@EIA_REF_ID, 2027, 4424.49),
(@EIA_REF_ID, 2028, 4469.26),
(@EIA_REF_ID, 2029, 4513.79),
(@EIA_REF_ID, 2030, 4562.01),
(@EIA_REF_ID, 2031, 4612.39),
(@EIA_REF_ID, 2032, 4674.74),
(@EIA_REF_ID, 2033, 4750.70),
(@EIA_REF_ID, 2034, 4842.46),
(@EIA_REF_ID, 2035, 4937.11),
(@EIA_REF_ID, 2036, 5032.98),
(@EIA_REF_ID, 2037, 5127.24),
(@EIA_REF_ID, 2038, 5202.18),
(@EIA_REF_ID, 2039, 5287.41),
(@EIA_REF_ID, 2040, 5367.50),
(@EIA_REF_ID, 2041, 5446.72),
(@EIA_REF_ID, 2042, 5521.45),
(@EIA_REF_ID, 2043, 5588.93),
(@EIA_REF_ID, 2044, 5652.74),
(@EIA_REF_ID, 2045, 5715.77),
(@EIA_REF_ID, 2046, 5779.68),
(@EIA_REF_ID, 2047, 5839.05),
(@EIA_REF_ID, 2048, 5894.13),
(@EIA_REF_ID, 2049, 5945.82),
(@EIA_REF_ID, 2050, 5995.21);

COMMIT;