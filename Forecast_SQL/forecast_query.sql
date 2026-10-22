-- ============================================================
-- forecast_query.sql
-- Purpose:
-- Query total U.S. electricity demand forecasts only.
-- ============================================================

SELECT 
    v.year,
    v.demand_TWh,
    m.source,
    m.scenario_original,
    CONCAT(m.source, ' | ', m.scenario_original) AS curve

FROM forecast_values v
JOIN forecast_metadata m
    ON v.forecast_id = m.forecast_id

ORDER BY 
    curve,
    v.year;
    
    