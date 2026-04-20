# Open Air Quality Pipeline

**A batch ELT pipeline that works with data from [OpenAQ](https://openaq.org/)**

This project demonstrates a data engineering workflow using **Terraform**, **Kestra**, **dbt**, **Neon Serverless Postgres**, and **Streamlit**. It pulls historical air quality measurements (PM2.5, PM10, etc.) for selected cities (Nairobi, New Delhi, Addis Ababa, Kigali, New York City), loads them incrementally into a warehouse, applies dimensional modeling with AQI calculations, and serves interactive dashboards.

Built as part of a data engineering assignment to showcase end-to-end batch pipeline orchestration and analytics.

<img width="1017" height="465" alt="Temporal Trends" src="https://github.com/user-attachments/assets/f824074c-7608-4d13-a34b-9855723ffb99" />

<img width="955" height="326" alt="Air quality Summary" src="https://github.com/user-attachments/assets/80b37f9f-5e47-4ffe-8106-a9decb9ed20e" />

Follow these steps to reproduce the full project on your machine.

### Prerequisites
- Linux/macOS (or WSL on Windows)
- Git installed
- Docker and Docker Compose installed (required for Kestra)
- Terraform installed
- A free [Neon](https://neon.tech) account (sign up at console.neon.tech)

### Step 1: Clone the Repository
```bash
git clone https://github.com/dukesync/Carriers_on_Time.git
cd Carriers_on_Time
```
### Step 2: Set Up Neon Authentication (Permanent)

- Get your API KEY in the neon console
- Add your key to shell
```bash
echo 'export NEON_API_KEY=your_actual_neon_api_key_here' >> ~/.bashrc
source ~/.bashrc
```
- The Terraform Neon provider will automatically read NEON_API_KEY

### Step 3: Configure Terraform Variables
- Edit (or create) terraform.tfvars and add your Neon Organization ID:
```bash
org_id = "your_neon_organization_id_here"   # Found in Neon Console → Account Settings
region_id = "eu-central-1"                  # or your preferred region
```
- Other variables are defined in variables.tf.
- After this run and copy the connection details, they would be utilized later on, e.g., (database name and user):
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
### Step 4: Set Up Python Environment with uv
- If uv is not present you could install it via the pip command, otherwise run the next command
```bash
pip install uv
uv sync
source .venv/bin/activate
```
### Step 5: Set Up Kestra (Orchestration)
- 1. Navigate into the pipeline directory
- 2. Create a dotenv file (.env), it should look similar to this structure. For database connection, details can be found in the connection string of your neon db project inside your neon dashboard.
```dotenv
# Kestra internal DB
KESTRA_DB_PASSWORD=k3str4

# Kestra UI login
KESTRA_USER=admiin@kestra.io
KESTRA_PASSWORD=Admin123477!

# Neon database connection
ENV_NEON_DB_USER=dukesync         
ENV_NEON_DB_PASSWORD=your_neon_db_password
ENV_NEON_JDBC_URL=jdbc:postgresql://your-neon-host.eu-central-1.aws.neon.tech:5432/air_quality_test
ENV_NEON_DATABASE_URL=postgresql://your-neon-host.eu-central-1.aws.neon.tech:5432/air_quality_test

# GitHub config (for dbt code sync)
ENV_GITHUB_USERNAME=dukesync
ENV_GITHUB_TOKEN=ghp_your_personal_access_token_here #should be created from your repo, under: https://github.com/settings/tokens

# dbt profile config
ENV_DBT_PROFILE_USER=dukesync_admin
ENV_DBT_PROFILE_PASSWORD=your_neon_db_password
ENV_DBT_PROFILE_HOST=your-neon-host.eu-central-1.aws.neon.tech
ENV_DBT_PROFILE_DB=air_quality_test
ENV_DBT_PROFILE_SCHEMA=analytics
```
- 3. Start Kestra using Docker Compose:
```bash
docker compose up -d
```
- Open Kestra on you browser, login using the Kestra UI login credential, create a new flow and copy the flow inside pipeline/Kestra_Flow.
### Step 7: Run the Pipeline and Dashboard
- Kestra is ran via the UI.
- for streamlit, navigate to dashboard folder and run
```bash
cd pipeline/dashboard
uv run streamlit run app.py
```
 

This project ingests historical and near-real-time air quality measurements from [OpenAQ](https://openaq.org/), the leading open platform fighting air inequality through open data. It processes data for selected cities (Nairobi, New Delhi, Addis Ababa, Kigali, New York City) and transforms it into analytics-ready models with AQI calculations.

## Features

- **Automated daily/periodic ingestion** of the last 60 days of data (with incremental updates to avoid duplicates)
- **Robust deduplication** using unique constraints and timestamp filtering
- **Dimensional modeling** with staging, facts, and dimensions (dbt)
- **Air Quality Index (AQI)** calculation using EPA-style breakpoints (PM2.5, PM10, PM1, etc.)
- **Daily aggregated reports** with dominant pollutant, AQI category, and city-level summaries
- **Serverless Postgres warehouse** powered by Neon (auto-scaling + branching)
- **Orchestration** with Kestra (YAML-defined flows, Git sync, selectable dbt commands)
- **Analytics dashboard** built with Streamlit
- **IaC** for infrastructure with Terraform

## Tech Stack

| Layer              | Technology                          | Purpose |
|--------------------|-------------------------------------|--------|
| **Infrastructure** | Terraform + Neon                    | Provision Postgres database & roles |
| **Orchestration**  | Kestra                              | Workflow scheduling, Python ingestion, dbt runs |
| **Ingestion**      | Python + psycopg2 + OpenAQ S3 Archive | Daily CSV.gz download & load |
| **Transformation** | dbt (Postgres)                      | Staging → Dimensional models + reports |
| **Warehouse**      | Neon Serverless Postgres            | Raw + analytics schemas |
| **Visualization**  | Streamlit                           | Interactive dashboards & reports |
