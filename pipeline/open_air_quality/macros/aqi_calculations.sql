{% macro pm25_aqi(concentration) %}
    CASE 
        WHEN {{ concentration }} IS NULL THEN NULL
        WHEN {{ concentration }} <= 9.0 THEN 
            ROUND( (50.0 / 9.0) * {{ concentration }} )
        WHEN {{ concentration }} <= 35.4 THEN 
            ROUND( 51 + ((100 - 51) / (35.4 - 9.1)) * ({{ concentration }} - 9.1) )
        WHEN {{ concentration }} <= 55.4 THEN 
            ROUND( 101 + ((150 - 101) / (55.4 - 35.5)) * ({{ concentration }} - 35.5) )
        WHEN {{ concentration }} <= 125.4 THEN 
            ROUND( 151 + ((200 - 151) / (125.4 - 55.5)) * ({{ concentration }} - 55.5) )
        WHEN {{ concentration }} <= 225.4 THEN 
            ROUND( 201 + ((300 - 201) / (225.4 - 125.5)) * ({{ concentration }} - 125.5) )
        ELSE 
            ROUND( 301 + ((500 - 301) / (999.9 - 225.5)) * ({{ concentration }} - 225.5) )
    END
{% endmacro %}

{% macro calculate_aqi_subindex(concentration, pollutant_code) %}
    CASE 
        -- PM2.5 (official EPA 2024 breakpoints)
        WHEN {{ pollutant_code }} = 'pm25' THEN
            {{ pm25_aqi(concentration) }}

        -- PM10 (standard EPA breakpoints, unchanged)
        WHEN {{ pollutant_code }} = 'pm10' THEN
            CASE 
                WHEN {{ concentration }} IS NULL THEN NULL
                WHEN {{ concentration }} <= 54 THEN 
                    ROUND( (50.0 / 54.0) * {{ concentration }} )
                WHEN {{ concentration }} <= 154 THEN 
                    ROUND( 51 + ((100 - 51) / (154 - 55)) * ({{ concentration }} - 55) )
                WHEN {{ concentration }} <= 254 THEN 
                    ROUND( 101 + ((150 - 101) / (254 - 155)) * ({{ concentration }} - 155) )
                WHEN {{ concentration }} <= 354 THEN 
                    ROUND( 151 + ((200 - 151) / (354 - 255)) * ({{ concentration }} - 255) )
                WHEN {{ concentration }} <= 424 THEN 
                    ROUND( 201 + ((300 - 201) / (424 - 355)) * ({{ concentration }} - 355) )
                ELSE 
                    ROUND( 301 + ((500 - 301) / (999.9 - 425)) * ({{ concentration }} - 425) )
            END

        -- PM1: Using same breakpoints as PM2.5 (reasonable proxy for ultrafine particles)
        WHEN {{ pollutant_code }} = 'pm1' THEN
            {{ pm25_aqi(concentration) }}

        ELSE NULL
    END
{% endmacro %}

{% macro get_aqi_category(aqi_value) %}
    CASE 
        WHEN {{ aqi_value }} IS NULL THEN NULL
        WHEN {{ aqi_value }} <= 50 THEN 'Good'
        WHEN {{ aqi_value }} <= 100 THEN 'Moderate'
        WHEN {{ aqi_value }} <= 150 THEN 'Unhealthy for Sensitive Groups'
        WHEN {{ aqi_value }} <= 200 THEN 'Unhealthy'
        WHEN {{ aqi_value }} <= 300 THEN 'Very Unhealthy'
        ELSE 'Hazardous'
    END
{% endmacro %}