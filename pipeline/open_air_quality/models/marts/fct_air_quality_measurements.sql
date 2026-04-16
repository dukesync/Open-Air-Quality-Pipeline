{{ config(
materialized='incremental',
unique_key='measurement_id',
indexes=[
{'columns': ['measurement_date']},
{'columns': ['location_id', 'measurement_date']}
]
) }}

with measurements as (

    select
        location as sensor_station,
        parameter,
        parameter_value,
        parameter_unit,
        measurement_datetime,
        measurement_date
    from {{ ref('stg_air_quality_measurements') }}

),

dim_param as (

    select
        parameter_id,
        parameter_code,
        unit
    from {{ ref('dim_parameter') }}

),

dim_loc as (

    select
        location_id,
        sensor_station
    from {{ ref('dim_location') }}

)

select
    -- stable deterministic surrogate key
    md5( coalesce(cast(l.location_id as text), '') || '|' || 
        coalesce(cast(p.parameter_id as text), '') || '|' || 
        coalesce(cast(m.measurement_datetime as text), '')
     )::text as measurement_id,
    
    -- foreign keys
    l.location_id,
    p.parameter_id,

    -- fact columns
    m.measurement_datetime,
    m.measurement_date,
    m.parameter_value

from measurements m

left join dim_loc l
    on m.sensor_station = l.sensor_station

left join dim_param p
    on m.parameter = p.parameter_code
    and m.parameter_unit = p.unit

{% if is_incremental() %}

--  Process new OR recently updated data
where m.measurement_datetime >= (
select max(measurement_datetime)
from {{ this }}
)

{% endif %}