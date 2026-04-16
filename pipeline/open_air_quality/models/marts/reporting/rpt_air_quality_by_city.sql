{{ config(
    materialized='table'
) }}

WITH daily AS (
    SELECT * 
    FROM {{ ref('rpt_airquality_daily') }}
),

city_summary AS (
    SELECT 
        city,
        country,
        COUNT(*) AS days_monitored,

        -- Averages
        ROUND(AVG(overall_aqi)::numeric, 0) AS avg_aqi,
        ROUND(AVG(pm25_avg)::numeric, 1) AS avg_pm25,
        ROUND(AVG(pm10_avg)::numeric, 1) AS avg_pm10,
        ROUND(AVG(pm1_avg)::numeric, 1) AS avg_pm1,
        ROUND(AVG(temperature_c)::numeric, 1) AS avg_temperature_c,
        ROUND(AVG(relative_humidity_pct)::numeric, 1) AS avg_rh_pct,

        -- Most common AQI category
        MODE() WITHIN GROUP (ORDER BY aqi_category) AS most_common_category,

        -- Category breakdown percentages
        ROUND(100.0 * COUNT(CASE WHEN aqi_category = 'Good' THEN 1 END) 
              / NULLIF(COUNT(*), 0), 1) AS pct_good,
        ROUND(100.0 * COUNT(CASE WHEN aqi_category = 'Moderate' THEN 1 END) 
              / NULLIF(COUNT(*), 0), 1) AS pct_moderate,
        ROUND(100.0 * COUNT(CASE WHEN aqi_category LIKE 'Unhealthy%' THEN 1 END) 
              / NULLIF(COUNT(*), 0), 1) AS pct_unhealthy_or_worse

    FROM daily
    GROUP BY city, country
)

SELECT 
    *,
    CASE 
        WHEN avg_aqi IS NULL THEN NULL
        WHEN avg_aqi <= 50 THEN 'Good'
        WHEN avg_aqi <= 100 THEN 'Moderate'
        WHEN avg_aqi <= 150 THEN 'Unhealthy for Sensitive Groups'
        WHEN avg_aqi <= 200 THEN 'Unhealthy'
        WHEN avg_aqi <= 300 THEN 'Very Unhealthy'
        ELSE 'Hazardous'
    END AS overall_air_quality_score
FROM city_summary
ORDER BY avg_aqi DESC