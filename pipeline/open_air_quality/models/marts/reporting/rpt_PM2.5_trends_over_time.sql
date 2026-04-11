SELECT 
    f.measurement_date, 
    AVG(f.parameter_value) as avg_value
FROM {{ref('fct_air_quality_measurements') }} f
JOIN {{ref('dim_parameter') }} p
ON f.parameter_id = p.parameter_id
WHERE p.parameter_code = 'pm25'
GROUP BY 1
ORDER BY 1;