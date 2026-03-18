#  dbt Project: Air Quality Transformations

##  Overview

This dbt project transforms raw air quality data into a structured, analytics-ready model.

It follows a layered approach:

```text
Staging → Dimensions → Fact → Reporting
```

The goal is to:

* Clean and standardize raw sensor data
* Model it into a **star schema**
* Provide ready-to-use datasets for analytics and dashboards

---

##  Model Layers

---

##  1. Staging Layer

### `stg_air_quality_measurements`

This is the first transformation step from the raw source.

**Purpose:**

* Clean raw OpenAQ data
* Standardize column names
* Convert timestamps into usable formats

**Key transformations:**

* `datetime` → `measurement_datetime`
* Extract `measurement_date`
* Rename fields for consistency:

  * `value` → `parameter_value`
  * `units` → `parameter_unit`

**Output includes:**

* Sensor identifiers
* Location details (lat/lon, station name)
* Measurement values (pollutants, weather data)

---

##  2. Dimension Tables

These tables provide descriptive context to the fact table.

---

### `dim_location`

**Purpose:**

* Create a unique list of sensor locations

**Logic:**

* Deduplicates locations from staging data
* Assigns a surrogate key: `location_id`
* Enriches data with:

  * `city`
  * `country`
  * `sensor_type` (e.g., reference grade vs air sensor)

**Why it matters:**

* Enables grouping and filtering by geography
* Separates descriptive attributes from raw measurements

---

### `dim_parameter`

**Purpose:**

* Standardize and describe measurement types

**Logic:**

* Extracts unique combinations of:

  * `parameter_code` (e.g., pm25, temperature)
  * `unit`
* Assigns a surrogate key: `parameter_id`
* Adds human-readable descriptions

**Examples:**

* `pm25` → Fine particulate matter
* `temperature` → Ambient temperature
* `wind_speed` → Wind speed

**Why it matters:**

* Makes raw sensor codes understandable
* Handles unit variations cleanly

---

##  3. Fact Table

### `fct_air_quality_measurements` (Incremental Model)

This is the **core table** of the data model.

---

###  Grain

```text
1 row = 1 measurement
(sensor + parameter + timestamp)
```

---

###  Key Features

####  Incremental Processing

* Only processes **new data** on each run
* Uses:

  ```sql
  where measurement_datetime >= (select max(measurement_datetime) from {{ this }})
  ```
* Prevents full table rebuilds

---

####  Deterministic Surrogate Key

```sql
md5(location_id || parameter_id || measurement_datetime)
```

* Ensures uniqueness
* Prevents duplicates
* Stable across runs

---

####  Joins

* Links to:

  * `dim_location`
  * `dim_parameter`

---

###  Output Columns

* `measurement_id` (primary key)
* `location_id` (FK)
* `parameter_id` (FK)
* `measurement_datetime`
* `measurement_date`
* `parameter_value`

---

##  4. Reporting Layer

These models are built for analytics and BI tools.

---

### `rpt_daily_air_quality`

**Purpose:**

* Track pollution trends over time

**Aggregations:**

* Average, min, max values
* Measurement counts

**Grain:**

```text
date + city + parameter
```

---

### `rpt_weather_pollution`

**Purpose:**

* Analyze relationship between weather and pollution

**Metrics:**

* Average temperature
* Average wind speed
* Average PM2.5

**Grain:**

```text
date + city
```

---

### `rpt_city_pollution_comparison`

**Purpose:**

* Compare pollution levels across cities

**Filters:**

* Focus on major pollutants:

  * PM2.5, PM10, CO, NO2, O3

**Grain:**

```text
city + parameter
```

---

##  Data Model (Star Schema)

```text
             dim_location
                   │
                   │
dim_parameter ─── fct_air_quality_measurements
                   │
                   │
             Reporting Models
```

---

##  Key Design Choices

###  Star Schema

* Simplifies querying
* Optimized for analytics

###  Incremental Fact Table

* Efficient for time-series sensor data
* Avoids recomputing historical data

###  Separation of Concerns

* Staging = cleaning
* Dimensions = context
* Fact = measurements
* Reporting = analytics

---

##  How to Run

```bash
dbt run
```

To rebuild everything:

```bash
dbt run --full-refresh
```

---

##  Documentation

Generate dbt docs:

```bash
dbt docs generate
dbt docs serve
```

This provides:

* Model lineage (DAG)
* Dependencies
* Metadata

---

##  Summary

This dbt project transforms raw environmental sensor data into a structured, scalable model that supports:

* Time-series analysis
* City-level comparisons
* Weather vs pollution insights

It is designed to reflect **real-world data engineering practices** for handling continuously growing datasets.

---
