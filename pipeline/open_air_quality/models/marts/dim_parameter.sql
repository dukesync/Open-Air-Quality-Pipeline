-- dim_parameter.sql
with params as (
    select distinct
        parameter as parameter_code,
        parameter_unit as unit
    from {{ ref('stg_air_quality_measurements') }}
)

select
    row_number() over () as parameter_id,
    parameter_code,
    unit,
    case
        when parameter_code ilike 'pm1' then 'Ultrafine particles'
        when parameter_code ilike 'pm25' then 'Fine particulate matter'
        when parameter_code ilike 'pm10' then 'Coarse particulate matter'
        when parameter_code ilike 'um003' then 'Tiny particle count (um003)'
        when parameter_code ilike 'co' and unit ilike '%µg%' then 'Carbon monoxide mass concentration'
        when parameter_code ilike 'co' and unit ilike '%ppb%' then 'Carbon monoxide gas concentration'
        when parameter_code ilike 'no' and unit ilike '%ppb%' then 'Nitric oxide gas concentration'
        when parameter_code ilike 'no2' and unit ilike '%ppb%' then 'Nitrogen dioxide gas concentration'
        when parameter_code ilike 'no2' and unit ilike '%µg%' then 'Nitrogen dioxide mass concentration'
        when parameter_code ilike 'nox' then 'Nitrogen oxides (NO + NO2)'
        when parameter_code ilike 'o3' then 'Ozone mass concentration'
        when parameter_code ilike 'so2' and unit ilike '%ppb%' then 'Sulfur dioxide gas concentration'
        when parameter_code ilike 'so2' and unit ilike '%µg%' then 'Sulfur dioxide mass concentration'
        when parameter_code ilike 'temperature' then 'Ambient temperature'
        when parameter_code ilike 'relativehumidity' then 'Relative Humidity'
        when parameter_code ilike 'wind_speed' then 'Wind speed'
        when parameter_code ilike 'wind_direction' then 'Wind direction'
        else 'Other / unknown'
    end as description
from params
order by parameter_code



{# -- dim_parameter.sql
with params as (
    select distinct
        parameter as parameter_code,
        parameter_unit as unit
    from {{ ref('stg_air_quality_measurements') }}
)

select
    row_number() over () as parameter_id,
    parameter_code,
    unit,
    case
        when parameter_code ilike 'pm1' then 'Ultrafine particles'
        when parameter_code ilike 'pm25' then 'Fine particulate matter'
        when parameter_code ilike 'pm10' then 'Coarse particulate matter'
        when parameter_code ilike 'um003' then 'Tiny particle count (um003)'
        when parameter_code ilike 'co' and unit ilike '%µg%' then 'Carbon monoxide mass concentration'
        when parameter_code ilike 'co' and unit ilike '%ppb%' then 'Carbon monoxide gas concentration'
        when parameter_code ilike 'no' and unit ilike '%ppb%' then 'Nitric oxide gas concentration'
        when parameter_code ilike 'no2' and unit ilike '%ppb%' then 'Nitrogen dioxide gas concentration'
        when parameter_code ilike 'no2' and unit ilike '%µg%' then 'Nitrogen dioxide mass concentration'
        when parameter_code ilike 'nox' then 'Nitrogen oxides (NO + NO2)'
        when parameter_code ilike 'o3' then 'Ozone mass concentration'
        when parameter_code ilike 'so2' and unit ilike '%ppb%' then 'Sulfur dioxide gas concentration'
        when parameter_code ilike 'so2' and unit ilike '%µg%' then 'Sulfur dioxide mass concentration'
        when parameter_code ilike 'temperature' then 'Ambient temperature'
        when parameter_code ilike 'rh' then 'Relative Humidity'
        when parameter_code ilike 'wind speed' then 'Wind speed'
        when parameter_code ilike 'wind direction' then 'Wind direction'
        else 'Other / unknown'
    end as description
from params
order by parameter_code #}