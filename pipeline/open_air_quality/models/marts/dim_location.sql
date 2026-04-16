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
        when sensor_station ilike '%Addis Ababa Central%' then 'Reference grade'
        when sensor_station ilike '%Kigali_Rwanda%' then 'Air sensor'
        when sensor_station ilike '%Downtown Manhattan%' then 'Air sensor'
        else 'Other'
    end as sensor_type,
    case
        when sensor_station ilike '%Delhi%' then 'New Delhi'
        when sensor_station ilike '%Providence Academy%' then 'Nairobi'
        when sensor_station ilike '%Addis Ababa Central%' then 'Addis Ababa'
        when sensor_station ilike '%Kigali_Rwanda%' then 'Kigali'
        when sensor_station ilike '%Downtown Manhattan%' then 'New York City'
        else null
    end as city,
    case
        when sensor_station ilike '%Delhi%' then 'India'
        when sensor_station ilike '%Providence Academy%' then 'Kenya'
        when sensor_station ilike '%Addis Ababa Central%' then 'Ethiopia'
        when sensor_station ilike '%Kigali_Rwanda%' then 'Rwanda'
        when sensor_station ilike '%Downtown Manhattan%' then 'USA'
        else null
    end as country
from locs

