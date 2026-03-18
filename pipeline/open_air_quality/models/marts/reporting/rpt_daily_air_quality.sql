-- Pollution Comparison Between Cities
WITH measurements AS (

SELECT
        f.measurement_date,
        l.city,
        l.sensor_type,
        p.parameter_code,
        avg(f.parameter_value)AS avg_value,
        min(f.parameter_value)AS min_value,
        max(f.parameter_value)AS max_value,
        p.unit,
count(*) AS measurements_count

FROM {{ref('fct_air_quality_measurements') }} f

JOIN {{ref('dim_location') }} l
ON f.location_id= l.location_id

JOIN {{ref('dim_parameter') }} p
ON f.parameter_id= p.parameter_id

GROUP BY
        f.measurement_date,
        l.city,
        l.sensor_type,
        p.parameter_code,
        p.unit
    
)

SELECT * FROM measurements