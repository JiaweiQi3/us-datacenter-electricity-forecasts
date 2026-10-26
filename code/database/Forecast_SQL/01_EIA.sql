-- ============================================================
-- 01_EIA.sql
-- Source: EIA
-- Dataset: Annual Energy Outlook (AEO) 2025 Reference Case
-- Description: Total electricity demand forecast (Table 8)
-- ============================================================
USE us_dc_energy_forecast;
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;


DELETE FROM forecast_values
WHERE forecast_id IN (
    SELECT forecast_id 
    FROM forecast_metadata 
    WHERE source = 'EIA'
);

DELETE FROM forecast_metadata
WHERE source = 'EIA';


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
    'EIA',
    'U.S. Energy Information Administration',
    'Reference case',
    'mid',
    'national',
    'USA',
    2024,
    2050,
    'BkWh (equivalent to TWh)',
    'Official EIA AEO 2025 reference case electricity demand forecast (Table 8)'
);

SET @EIA_ID = LAST_INSERT_ID();


-- ============================================================
-- 2. INSERT VALUES
-- ============================================================

INSERT INTO forecast_values (forecast_id, year, demand_TWh) VALUES
(@EIA_ID, 2024, 4163.546),
(@EIA_ID, 2025, 4219.155),
(@EIA_ID, 2026, 4263.316),
(@EIA_ID, 2027, 4322.157),
(@EIA_ID, 2028, 4374.008),
(@EIA_ID, 2029, 4435.316),
(@EIA_ID, 2030, 4497.402),
(@EIA_ID, 2031, 4563.315),
(@EIA_ID, 2032, 4644.068),
(@EIA_ID, 2033, 4734.206),
(@EIA_ID, 2034, 4836.527),
(@EIA_ID, 2035, 4944.940),
(@EIA_ID, 2036, 5056.842),
(@EIA_ID, 2037, 5164.092),
(@EIA_ID, 2038, 5268.104),
(@EIA_ID, 2039, 5372.156),
(@EIA_ID, 2040, 5471.946),
(@EIA_ID, 2041, 5566.020),
(@EIA_ID, 2042, 5654.602),
(@EIA_ID, 2043, 5738.960),
(@EIA_ID, 2044, 5817.032),
(@EIA_ID, 2045, 5890.234),
(@EIA_ID, 2046, 5960.699),
(@EIA_ID, 2047, 6036.159),
(@EIA_ID, 2048, 6115.203),
(@EIA_ID, 2049, 6196.264),
(@EIA_ID, 2050, 6281.289);


COMMIT;