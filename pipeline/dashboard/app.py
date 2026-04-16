import streamlit as st
import pandas as pd
from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv

# Setup and Page Config
load_dotenv()
st.set_page_config(page_title="DukeSync Air Quality Dashboard", layout="wide")

st.title("DukeSync: Air Quality Analytics")
st.markdown("""This dashboard visualizes air quality data processed""")

# 2. Database Connection
def get_connection():
    conn_url = os.getenv("NEON_DATABASE_URL")
    return create_engine(conn_url)

engine = get_connection()

# Connection check
try:
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    st.success(" Connected to Neon Postgres")
except Exception as e:
    st.error(f"Connection failed: {e}")

# 3. Sidebar Filters
st.sidebar.header("Dashboard Filters")

params_df = pd.read_sql("""
    SELECT description, parameter_code 
    FROM analytics.dim_parameter 
    WHERE parameter_code IN ('pm25', 'pm10', 'pm1')
""", engine)

selected_param_desc = st.sidebar.selectbox(
    "Select Pollutant for Trend", 
    params_df['description'].unique()
)
selected_code = params_df[params_df['description'] == selected_param_desc]['parameter_code'].values[0]

# Load Data from Reporting Models
@st.cache_data(ttl=600)
def load_daily_aqi():
    query = """
    SELECT * 
    FROM analytics.rpt_airquality_daily
    ORDER BY measurement_date DESC
    """
    return pd.read_sql(query, engine)

@st.cache_data(ttl=600)
def load_city_summary():
    query = """
    SELECT  
        city,
        country,
        days_monitored,
        avg_aqi,
        avg_pm25,
        avg_temperature_c,
        avg_rh_pct,
        most_common_category,
        pct_good,
        pct_moderate,
        pct_unhealthy_or_worse 
    FROM analytics.rpt_air_quality_by_city
    ORDER BY avg_aqi DESC
    """
    return pd.read_sql(query, engine)

daily_df = load_daily_aqi()
city_df = load_city_summary()

# Overall Air Quality Summary - Dynamic Tiles (Best → Worst)
st.subheader("Overall Air Quality Summary")

latest_date = daily_df['measurement_date'].max() if not daily_df.empty else None

if latest_date:
    latest_data = daily_df[daily_df['measurement_date'] == latest_date].copy()
    
    if not latest_data.empty:
        # Sort from best air quality to worst
        # latest_data = latest_data.sort_values(by='overall_aqi', ascending=True)
        latest_data = (
                        daily_df.sort_values('measurement_date')
                        .groupby('city', as_index=False)
                        .tail(1)
                    ).sort_values(by='overall_aqi', ascending=True)
        
        # Create dynamic columns (max 4 per row)
        num_cities = len(latest_data)
        cols = st.columns(min(4, num_cities))
        
        for idx, row in enumerate(latest_data.itertuples()):
            col = cols[idx % len(cols)]
            
            with col:
                aqi_value = int(row.overall_aqi)
                category = row.aqi_category
                city_name = row.city
                
                # AQI level emoji
                if aqi_value <= 50:
                    emoji = "🟢"
                elif aqi_value <= 100:
                    emoji = "🟡"
                elif aqi_value <= 150:
                    emoji = "🟠"
                else:
                    emoji = "🔴"
                
                st.metric(
                    label=f"{emoji} {city_name}",
                    value=f"{aqi_value} AQI",
                    delta=category
                )
                st.caption(f"{latest_date} • Dominant: {row.dominant_pollutant.upper() if pd.notna(row.dominant_pollutant) else 'N/A'}")
    else:
        st.warning("No data available for the latest date.")
else:
    st.warning("No data found.")

# City Comparison
st.subheader("🏙️ Air Quality by City (3-Month Summary)")

st.dataframe(
    city_df.style.format({
        "avg_aqi": "{:.0f}",
        "avg_pm25": "{:.1f}",
        "avg_temperature_c": "{:.1f}",
        "avg_rh_pct": "{:.1f}",
        "pct_good": "{:.1f}%",
        "pct_moderate": "{:.1f}%",
        "pct_unhealthy_or_worse": "{:.1f}%"
    }),
    width='stretch',
    hide_index=True,
    column_config={
        "city": st.column_config.TextColumn("City"),
        "country": st.column_config.TextColumn("Country"),
        "days_monitored": st.column_config.NumberColumn("Days Monitored"),
        "avg_aqi": st.column_config.NumberColumn("Avg AQI", format="%d"),
        "avg_pm25": st.column_config.NumberColumn("Avg PM2.5 (µg/m³)", format="%.1f"),
        "avg_temperature_c": st.column_config.NumberColumn("Avg Temp (°C)", format="%.1f"),
        "avg_rh_pct": st.column_config.NumberColumn("Avg RH (%)", format="%.1f"),
        "most_common_category": st.column_config.TextColumn("Most Common Category"),
        "pct_good": st.column_config.TextColumn("% Good"),
        "pct_moderate": st.column_config.TextColumn("% Moderate"),
        "pct_unhealthy_or_worse": st.column_config.TextColumn("% Unhealthy+")
    }
)

# 7. Temporal Trends
st.subheader(f"Temporal Trends")

col_trend1, col_trend2 = st.columns(2)

with col_trend1:
    st.caption("Overall AQI Trend (All Cities)")
    aqi_trend = daily_df.groupby('measurement_date')['overall_aqi'].mean().reset_index()
    st.line_chart(aqi_trend.set_index('measurement_date'), width='stretch')

with col_trend2:
    st.caption(f"{selected_param_desc} Trend")
    # Using PM2.5 as main example
    pm_trend = daily_df.groupby('measurement_date')['pm25_avg'].mean().reset_index()
    st.line_chart(pm_trend.set_index('measurement_date'), width='stretch')

st.caption("Built with dbt reporting models • AQI calculated using US EPA methodology")