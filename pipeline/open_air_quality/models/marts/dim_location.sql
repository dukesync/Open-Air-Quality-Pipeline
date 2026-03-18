with locs as (
    select distinct
        location as sensor_station,
        lat,
        lon
    from {{ ref('stg_air_quality_measurements') }}
)
select
    row_number() over () as location_id,
    sensor_station,
    lat,
    lon,
    case
        when sensor_station ilike '%Delhi%' then 'Reference grade'
        when sensor_station ilike '%Providence Academy%' then 'Air sensor'
        when sensor_station ilike '%Nakuru%' then 'Air sensor'
        else 'Other'
    end as sensor_type,
    case
        when sensor_station ilike '%Delhi%' then 'New Delhi'
        when sensor_station ilike '%Providence Academy%' then 'Nairobi'
        when sensor_station ilike '%Nakuru%' then 'Nakuru'
        else null
    end as city,
    case
        when sensor_station ilike '%Delhi%' then 'India'
        when sensor_station ilike '%Providence Academy%' then 'Kenya'
        when sensor_station ilike '%Nakuru%' then 'Kenya'
        else null
    end as country
from locs

