# =============================================================================
# Simple BigQuery Module Example
# This example demonstrates basic usage of the BigQuery module
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
# Provider Configuration
# =============================================================================

provider "google" {
  project = var.project_id
  region  = var.region
}

# =============================================================================
# Simple BigQuery Module Usage
# =============================================================================

module "bigquery_simple" {
  source = "../../"

  # Required variables
  project_id = var.project_id
  dataset_id = "simple_analytics"

  # Basic dataset configuration
  dataset_name = "Simple Analytics Dataset"
  description  = "A simple dataset for basic analytics"
  location     = "US"

  # Basic table
  tables = [
    {
      table_id = "users"
      schema = jsonencode([
        {
          name        = "id"
          type        = "INTEGER"
          mode        = "REQUIRED"
          description = "User ID"
        },
        {
          name        = "name"
          type        = "STRING"
          mode        = "REQUIRED"
          description = "User name"
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
        }
      ])
      labels = {
        table_type = "dimension"
        data_type  = "user_data"
      }
    }
  ]

  # Basic view
  views = [
    {
      view_id = "active_users"
      query = <<-SQL
        SELECT
          id,
          name,
          email,
          created_at
        FROM `${var.project_id}.simple_analytics.users`
        WHERE created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
        ORDER BY created_at DESC
      SQL
      labels = {
        view_type = "filtered"
      }
    }
  ]

  # Dataset labels
  dataset_labels = {
    environment = "development"
    team        = "analytics"
    managed_by  = "terraform"
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "dataset_id" {
  description = "The ID of the created BigQuery dataset"
  value       = module.bigquery_simple.dataset_id
}

output "dataset_location" {
  description = "The location of the BigQuery dataset"
  value       = module.bigquery_simple.dataset_location
}

output "table_ids" {
  description = "The IDs of the created tables"
  value       = module.bigquery_simple.table_ids
}

output "view_ids" {
  description = "The IDs of the created views"
  value       = module.bigquery_simple.view_ids
}

output "dataset_self_link" {
  description = "The self link of the BigQuery dataset"
  value       = module.bigquery_simple.dataset_self_link
}