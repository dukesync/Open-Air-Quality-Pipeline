SELECT
    -- identifiers
    location_id,
    sensors_id,
    -- timestamps
    datetime as measurement_datetime,
    datetime::date as measurement_date,
    -- locations
    location,
    lat,
    lon,
    -- measurements
    parameter,
    value as parameter_value,
    units as parameter_unit
FROM {{ source('raw_open_air_quality', 'raw_openaq_measurements') }}
