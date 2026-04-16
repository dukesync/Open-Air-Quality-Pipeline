{{ config(
    materialized='table',
    unique_key=['measurement_date', 'location_id'],
    indexes=[
        {'columns': ['measurement_date']},
        {'columns': ['location_id', 'measurement_date']}
    ]
) }}

WITH daily_averages AS (
    SELECT 
        f.measurement_date,
        l.location_id,
        l.city,
        l.country,
        p.parameter_code,
        AVG(f.parameter_value) AS avg_concentration,
        -- using MAX since they should be the same per day
        MAX(CASE WHEN p.parameter_code = 'temperature' THEN f.parameter_value END) AS avg_temperature,
        MAX(CASE WHEN p.parameter_code = 'relativehumidity' THEN f.parameter_value END) AS avg_rh
    FROM {{ ref('fct_air_quality_measurements') }} f
    JOIN {{ ref('dim_location') }} l ON f.location_id = l.location_id
    JOIN {{ ref('dim_parameter') }} p ON f.parameter_id = p.parameter_id
    WHERE p.parameter_code IN ('pm25', 'pm10', 'pm1', 'temperature', 'relativehumidity')
      AND f.parameter_value IS NOT NULL
    GROUP BY 1, 2, 3, 4, 5
),

aqi_subindices AS (
    SELECT 
        *,
        {{ calculate_aqi_subindex('avg_concentration', 'parameter_code') }} AS aqi_subindex
    FROM daily_averages
),

-- Get overall AQI and pivot the concentrations
daily_base AS (
    SELECT 
        measurement_date,
        location_id,
        city,
        country,
        MAX(CASE WHEN parameter_code = 'pm25' THEN avg_concentration END) AS pm25_avg,
        MAX(CASE WHEN parameter_code = 'pm10' THEN avg_concentration END) AS pm10_avg,
        MAX(CASE WHEN parameter_code = 'pm1'  THEN avg_concentration END) AS pm1_avg,
        MAX(CASE WHEN parameter_code = 'temperature' THEN avg_temperature END) AS temperature_c,
        MAX(CASE WHEN parameter_code = 'relativehumidity' THEN avg_rh END) AS relative_humidity_pct,

        -- Overall AQI = highest sub-index
        MAX(aqi_subindex) AS overall_aqi

    FROM aqi_subindices
    GROUP BY measurement_date, location_id, city, country
),

-- Find the dominant pollutant (the one with the highest aqi_subindex)
dominant AS (
    SELECT 
        measurement_date,
        location_id,
        parameter_code AS dominant_pollutant,
        ROW_NUMBER() OVER (PARTITION BY measurement_date, location_id 
                           ORDER BY aqi_subindex DESC) AS rn
    FROM aqi_subindices
    WHERE aqi_subindex IS NOT NULL
)

SELECT 
    b.*,
    d.dominant_pollutant,
    {{ get_aqi_category('b.overall_aqi') }} AS aqi_category
FROM daily_base b
LEFT JOIN dominant d 
    ON b.measurement_date = d.measurement_date 
   AND b.location_id = d.location_id 
   AND d.rn = 1
ORDER BY b.measurement_date DESC, b.city