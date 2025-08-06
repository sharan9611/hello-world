# =============================================================================
# Minimal BigQuery Module Example
# This example creates a basic BigQuery dataset with minimal configuration
# Only requires project_id to be set
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
}

# =============================================================================
# Minimal BigQuery Module Usage
# =============================================================================

module "bigquery_minimal" {
  source = "../../"

  # Only required variables
  project_id = var.project_id
  dataset_id = "minimal_dataset"

  # Optional: Basic configuration
  dataset_name = "Minimal Dataset"
  description  = "A minimal BigQuery dataset example"

  # Basic table with simple schema
  tables = [
    {
      table_id = "sample_table"
      schema = jsonencode([
        {
          name = "id"
          type = "INTEGER"
          mode = "REQUIRED"
        },
        {
          name = "message"
          type = "STRING"
          mode = "NULLABLE"
        }
      ])
    }
  ]
}

# =============================================================================
# Outputs
# =============================================================================

output "dataset_id" {
  description = "The ID of the created BigQuery dataset"
  value       = module.bigquery_minimal.dataset_id
}

output "dataset_self_link" {
  description = "The self link of the BigQuery dataset"
  value       = module.bigquery_minimal.dataset_self_link
}

output "table_ids" {
  description = "The IDs of the created tables"
  value       = module.bigquery_minimal.table_ids
}