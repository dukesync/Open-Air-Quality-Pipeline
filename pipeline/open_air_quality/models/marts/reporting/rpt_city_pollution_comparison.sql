-- Daily Air Quality Summary
SELECT
    l.city,
    p.parameter_code,
    avg(f.parameter_value) as avg_pollution
FROM {{ref('fct_air_quality_measurements') }} f

JOIN {{ref('dim_location') }} l
ON f.location_id= l.location_id

JOIN {{ref('dim_parameter') }} p
ON f.parameter_id= p.parameter_id

WHERE p.parameter_code IN ('pm25','pm10','pm1','co','no2','o3')

GROUP BY
    l.city,
    p.parameter_code