-- ============================================================
-- dc_forecast_query.sql
-- Purpose:
-- Query U.S. data center electricity demand forecasts only.
-- ============================================================

SELECT 
    v.year,
    v.demand_TWh,
    v.share_percent,
    m.source,
    m.scenario_original,
    CONCAT(m.source, ' | ', m.scenario_original) AS curve

FROM dc_forecast_values v
JOIN dc_forecast_metadata m
    ON v.dc_forecast_id = m.dc_forecast_id

ORDER BY 
    curve,
    v.year;

    