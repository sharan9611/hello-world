# =============================================================================
# Simple BigQuery Configuration
# This creates a basic BigQuery dataset with tables and views
# Only requires your GCP project_id
# =============================================================================

terraform {
  required_version = ">= 0.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0, < 6.0"
    }
  }
}

# =============================================================================
# Variables
# =============================================================================

variable "project_id" {
  description = "Your GCP Project ID"
  type        = string
  # Set this to your actual project ID
  default = "your-gcp-project-id"  # Change this to your project ID
}

# =============================================================================
# Provider Configuration
# =============================================================================

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

# =============================================================================
# BigQuery Module Usage
# =============================================================================

module "bigquery_simple" {
  source = "./"

  # Required variables
  project_id = var.project_id
  dataset_id = "analytics_dataset"

  # Dataset configuration
  dataset_name = "Analytics Dataset"
  description  = "Simple analytics dataset for demonstration"
  location     = "US"

  # Dataset labels
  dataset_labels = {
    environment = "demo"
    team        = "data"
    managed_by  = "terraform"
  }

  # Tables
  tables = [
    {
      table_id = "users"
      table_name = "Users Table"
      description = "User information table"
      schema = jsonencode([
        {
          name        = "user_id"
          type        = "INTEGER"
          mode        = "REQUIRED"
          description = "Unique user identifier"
        },
        {
          name        = "username"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Username"
        },
        {
          name        = "email"
          type        = "STRING"
          mode        = "NULLABLE"
          description = "User email address"
        },
        {
          name        = "created_at"
          type        = "TIMESTAMP"
          mode        = "REQUIRED"
          description = "Account creation timestamp"
        },
        {
          name        = "last_login"
          type        = "TIMESTAMP"
          mode        = "NULLABLE"
          description = "Last login timestamp"
        }
      ])
      labels = {
        table_type = "dimension"
        data_type  = "user_data"
      }
    },
    {
      table_id = "events"
      table_name = "Events Table"
      description = "User events tracking table with partitioning"
      schema = jsonencode([
        {
          name        = "event_id"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Unique event identifier"
        },
        {
          name        = "user_id"
          type        = "INTEGER"
          mode        = "REQUIRED"
          description = "User identifier"
        },
        {
          name        = "event_type"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "Type of event"
        },
        {
          name        = "event_data"
          type        = "JSON"
          mode        = "NULLABLE"
          description = "Event data payload"
        },
        {
          name        = "event_date"
          type        = "DATE"
          mode        = "REQUIRED"
          description = "Event date for partitioning"
        },
        {
          name        = "event_timestamp"
          type        = "TIMESTAMP"
          mode        = "REQUIRED"
          description = "Event timestamp"
        }
      ])
      clustering = ["user_id", "event_type"]
      time_partitioning = {
        type                     = "DAY"
        field                    = "event_date"
        require_partition_filter = false
      }
      labels = {
        table_type  = "fact"
        data_type   = "event_data"
        partitioned = "true"
      }
    }
  ]

  # Views
  views = [
    {
      view_id = "active_users"
      view_name = "Active Users View"
      description = "View of users who logged in recently"
      query = <<-SQL
        SELECT
          user_id,
          username,
          email,
          created_at,
          last_login
        FROM `${var.project_id}.analytics_dataset.users`
        WHERE last_login >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
        ORDER BY last_login DESC
      SQL
      labels = {
        view_type = "filtered"
        data_type = "user_data"
      }
    },
    {
      view_id = "daily_event_summary"
      view_name = "Daily Event Summary"
      description = "Daily aggregation of events by type"
      query = <<-SQL
        SELECT
          event_date,
          event_type,
          COUNT(*) as event_count,
          COUNT(DISTINCT user_id) as unique_users
        FROM `${var.project_id}.analytics_dataset.events`
        GROUP BY event_date, event_type
        ORDER BY event_date DESC, event_count DESC
      SQL
      labels = {
        view_type = "aggregated"
        data_type = "event_summary"
      }
    }
  ]

  # Simple routine (function)
  routines = [
    {
      routine_id      = "days_since_created"
      routine_type    = "SCALAR_FUNCTION"
      language        = "SQL"
      description     = "Calculate days since account creation"
      definition_body = "DATE_DIFF(CURRENT_DATE(), DATE(created_timestamp), DAY)"
      return_type     = jsonencode({"type" = "INT64"})
      arguments = [
        {
          name      = "created_timestamp"
          data_type = jsonencode({"type" = "TIMESTAMP"})
        }
      ]
    }
  ]
}

# =============================================================================
# Outputs
# =============================================================================

output "dataset_info" {
  description = "Information about the created BigQuery dataset"
  value = {
    dataset_id   = module.bigquery_simple.dataset_id
    dataset_name = module.bigquery_simple.dataset_name
    location     = module.bigquery_simple.dataset_location
    project      = module.bigquery_simple.dataset_project
    self_link    = module.bigquery_simple.dataset_self_link
  }
}

output "table_info" {
  description = "Information about created tables"
  value = {
    table_ids  = module.bigquery_simple.table_ids
    table_fqns = module.bigquery_simple.table_fqns
  }
}

output "view_info" {
  description = "Information about created views"
  value = {
    view_ids = module.bigquery_simple.view_ids
  }
}

output "routine_info" {
  description = "Information about created routines"
  value = {
    routine_ids = module.bigquery_simple.routine_ids
  }
}

output "summary" {
  description = "Summary of all created resources"
  value       = module.bigquery_simple.summary
}