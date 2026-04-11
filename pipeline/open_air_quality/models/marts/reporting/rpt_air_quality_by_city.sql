SELECT 
    l.city, 
    AVG(f.parameter_value) as avg_pm25
FROM {{ref('fct_air_quality_measurements') }} f
JOIN {{ref('dim_location') }} l ON f.location_id = l.location_id
JOIN {{ref('dim_parameter') }} p ON f.parameter_id = p.parameter_id
WHERE p.parameter_code = 'pm25'
GROUP BY 1
ORDER BY 2 ASC;