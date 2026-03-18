-- Weather vs Pollution Analysis
SELECT
    f.measurement_date,
    l.city,
    avg(CASE 
            WHEN p.parameter_code='temperature' 
            THEN f.parameter_value
        END) AS avg_temp,
    coalesce(
        avg(CASE 
            WHEN p.parameter_code='wind_speed' 
                THEN f.parameter_value
            END), 0) as avg_wind_speed,
    avg(CASE 
            WHEN p.parameter_code='pm25' 
            THEN f.parameter_value
        END) AS avg_pm25

FROM {{ref('fct_air_quality_measurements') }} f

JOIN {{ref('dim_location') }} l
ON f.location_id= l.location_id

JOIN {{ref('dim_parameter') }} p
ON f.parameter_id= p.parameter_id

GROUP BY
    f.measurement_date,
    l.city
ORDER BY
    f.measurement_date