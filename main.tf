terraform {
  required_providers {
    neon = {
      source  = "terraform-community-providers/neon"
      version = "0.1.12"
    }
  }
}

provider "neon" {
  # You can set the API key as an environment variable: export NEON_TOKEN='your_key'
}

# 1. Create the Project
resource "neon_project" "main" {
  name              = "air_quality_analytics"
  region_id         = var.region_id
  pg_version        = 17
  org_id            = var.org_id
  history_retention = 21600 # max allowed for your plan (6 ho

  branch = {
    name = "main"
    endpoint = {
      min_cu = 0.25
      max_cu = 2       # autoscale from 0.25 to 2 CU
    }
  }
}

# 2. Create the Database Owner Role
resource "neon_role" "db_owner" {
  name       = "dukesync_admin"
  project_id = neon_project.main.id
  branch_id  = neon_project.main.branch.id
}

# 3. Create the Database
resource "neon_database" "air_quality_db" {
  name       = "air_quality_test"
  owner_name = neon_role.db_owner.name
  project_id = neon_project.main.id
  branch_id  = neon_project.main.branch.id
}

# 4. (Optional) Create a specific branch for your analytics
resource "neon_branch" "analytics" {
  name       = "analytics_dev"
  project_id = neon_project.main.id
  parent_id  = neon_project.main.branch.id
}