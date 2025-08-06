# =============================================================================
# Complete BigQuery Module Example
# This example demonstrates all features of the comprehensive BigQuery module
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
# Local Values
# =============================================================================

locals {
  # Common labels
  common_labels = {
    environment = var.environment
    project     = var.project_id
    managed_by  = "terraform"
    team        = "data-engineering"
  }

  # Sample table schema
  sample_table_schema = jsonencode([
    {
      name = "id"
      type = "INTEGER"
      mode = "REQUIRED"
      description = "Unique identifier"
    },
    {
      name = "name"
      type = "STRING"
      mode = "REQUIRED"
      description = "Name field"
    },
    {
      name = "email"
      type = "STRING"
      mode = "NULLABLE"
      description = "Email address"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "REQUIRED"
      description = "Creation timestamp"
    },
    {
      name = "updated_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
      description = "Last update timestamp"
    }
  ])

  # Partitioned table schema
  partitioned_table_schema = jsonencode([
    {
      name = "transaction_id"
      type = "STRING"
      mode = "REQUIRED"
      description = "Transaction identifier"
    },
    {
      name = "user_id"
      type = "INTEGER"
      mode = "REQUIRED"
      description = "User identifier"
    },
    {
      name = "amount"
      type = "NUMERIC"
      mode = "REQUIRED"
      description = "Transaction amount"
    },
    {
      name = "transaction_date"
      type = "DATE"
      mode = "REQUIRED"
      description = "Transaction date for partitioning"
    },
    {
      name = "created_timestamp"
      type = "TIMESTAMP"
      mode = "REQUIRED"
      description = "Creation timestamp"
    }
  ])

  # External table schema for CSV
  external_csv_schema = jsonencode([
    {
      name = "product_id"
      type = "STRING"
      mode = "REQUIRED"
      description = "Product identifier"
    },
    {
      name = "product_name"
      type = "STRING"
      mode = "REQUIRED"
      description = "Product name"
    },
    {
      name = "category"
      type = "STRING"
      mode = "NULLABLE"
      description = "Product category"
    },
    {
      name = "price"
      type = "NUMERIC"
      mode = "REQUIRED"
      description = "Product price"
    }
  ])
}

# =============================================================================
# Comprehensive BigQuery Module Usage
# =============================================================================

module "bigquery_complete" {
  source = "../../"

  # Required variables
  project_id = var.project_id
  dataset_id = "${var.environment}_analytics_dataset"

  # Dataset configuration
  dataset_name                    = "Analytics Dataset - ${title(var.environment)}"
  description                     = "Comprehensive analytics dataset with all BigQuery features demonstrated"
  location                        = var.location
  delete_contents_on_destroy      = true
  default_table_expiration_ms     = 7776000000  # 90 days
  default_partition_expiration_ms = 2592000000  # 30 days
  max_time_travel_hours          = 168         # 7 days
  storage_billing_model          = "LOGICAL"
  is_case_insensitive            = false
  dataset_labels                 = local.common_labels
  resource_tags                  = {
    "data-classification" = "internal"
    "cost-center"        = "engineering"
  }

  # Dataset access control
  access = concat([
    {
      role          = "roles/bigquery.dataOwner"
      special_group = "projectOwners"
    },
    {
      role          = "roles/bigquery.dataEditor"
      special_group = "projectEditors"
    }
  ], var.data_analyst_email != null ? [{
    role         = "roles/bigquery.dataViewer"
    user_by_email = var.data_analyst_email
  }] : [], var.data_team_group_email != null ? [{
    role           = "roles/bigquery.dataViewer"
    group_by_email = var.data_team_group_email
  }] : [])

  # Regular tables
  tables = [
    {
      table_id                 = "users"
      table_name               = "Users Table"
      description              = "User information table"
      schema                   = local.sample_table_schema
      clustering               = ["name"]
      deletion_protection      = true
      require_partition_filter = false
      labels = merge(local.common_labels, {
        table_type = "dimension"
        data_type  = "user_data"
      })
    },
    {
      table_id    = "transactions"
      table_name  = "Transactions Table"
      description = "Daily partitioned transactions table with clustering"
      schema      = local.partitioned_table_schema
      clustering  = ["user_id", "transaction_id"]
      time_partitioning = {
        type                     = "DAY"
        field                    = "transaction_date"
        require_partition_filter = true
        expiration_ms            = "2592000000"  # 30 days
      }
      deletion_protection = true
      labels = merge(local.common_labels, {
        table_type = "fact"
        data_type  = "transaction_data"
        partitioned = "true"
      })
    },
    {
      table_id    = "products_range_partitioned"
      table_name  = "Products Range Partitioned"
      description = "Range partitioned products table"
      schema      = local.external_csv_schema
      range_partitioning = {
        field = "product_id"
        range = {
          start    = "1"
          end      = "10000"
          interval = "100"
        }
      }
      clustering = ["category"]
      labels = merge(local.common_labels, {
        table_type        = "dimension"
        partitioning_type = "range"
      })
    }
  ]

  # Views
  views = [
    {
      view_id     = "active_users"
      view_name   = "Active Users View"
      description = "View of active users from the last 30 days"
      query = <<-SQL
        SELECT
          id,
          name,
          email,
          created_at,
          updated_at
        FROM `${var.project_id}.${var.environment}_analytics_dataset.users`
        WHERE updated_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
        ORDER BY updated_at DESC
      SQL
      use_legacy_sql = false
      labels = merge(local.common_labels, {
        view_type = "filtered"
        data_type = "user_data"
      })
    },
    {
      view_id     = "transaction_summary"
      view_name   = "Transaction Summary View"
      description = "Aggregated transaction summary by user"
      query = <<-SQL
        SELECT
          user_id,
          COUNT(*) as transaction_count,
          SUM(amount) as total_amount,
          AVG(amount) as avg_amount,
          MIN(transaction_date) as first_transaction,
          MAX(transaction_date) as last_transaction
        FROM `${var.project_id}.${var.environment}_analytics_dataset.transactions`
        GROUP BY user_id
        HAVING COUNT(*) > 0
        ORDER BY total_amount DESC
      SQL
      use_legacy_sql = false
      labels = merge(local.common_labels, {
        view_type = "aggregated"
        data_type = "transaction_data"
      })
    }
  ]

  # Materialized views
  materialized_views = [
    {
      view_id             = "daily_transaction_stats"
      view_name           = "Daily Transaction Statistics"
      description         = "Materialized view of daily transaction statistics"
      enable_refresh      = true
      refresh_interval_ms = "3600000"  # 1 hour
      clustering          = ["transaction_date"]
      query = <<-SQL
        SELECT
          transaction_date,
          COUNT(*) as daily_transaction_count,
          SUM(amount) as daily_total_amount,
          AVG(amount) as daily_avg_amount,
          COUNT(DISTINCT user_id) as unique_users
        FROM `${var.project_id}.${var.environment}_analytics_dataset.transactions`
        GROUP BY transaction_date
      SQL
      time_partitioning = {
        type  = "DAY"
        field = "transaction_date"
      }
      labels = merge(local.common_labels, {
        view_type = "materialized"
        data_type = "transaction_stats"
      })
    }
  ]

  # External tables (only if buckets are specified)
  external_tables = concat(
    var.data_bucket != null ? [{
      table_id      = "external_products_csv"
      table_name    = "External Products CSV"
      description   = "External table reading from CSV files in Cloud Storage"
      source_format = "CSV"
      source_uris   = ["gs://${var.data_bucket}/products/*.csv"]
      schema        = local.external_csv_schema
      autodetect    = false
      csv_options = {
        quote                 = "\""
        allow_jagged_rows     = false
        allow_quoted_newlines = false
        encoding              = "UTF-8"
        field_delimiter       = ","
        skip_leading_rows     = 1
      }
      labels = merge(local.common_labels, {
        table_type = "external"
        source     = "csv"
      })
    }] : [],
    var.logs_bucket != null ? [{
      table_id      = "external_logs_json"
      table_name    = "External Logs JSON"
      description   = "External table reading from JSON log files"
      source_format = "NEWLINE_DELIMITED_JSON"
      source_uris   = ["gs://${var.logs_bucket}/logs/*.json"]
      autodetect    = true
      json_options = {
        encoding = "UTF-8"
      }
      labels = merge(local.common_labels, {
        table_type = "external"
        source     = "json"
      })
    }] : []
  )

  # Routines (Functions and Procedures)
  routines = [
    {
      routine_id      = "calculate_tax"
      routine_type    = "SCALAR_FUNCTION"
      language        = "SQL"
      description     = "Calculate tax amount based on amount and tax rate"
      definition_body = "amount * tax_rate"
      return_type     = jsonencode({"type" = "NUMERIC"})
      arguments = [
        {
          name      = "amount"
          data_type = jsonencode({"type" = "NUMERIC"})
        },
        {
          name      = "tax_rate"
          data_type = jsonencode({"type" = "NUMERIC"})
        }
      ]
    },
    {
      routine_id      = "update_user_stats"
      routine_type    = "PROCEDURE"
      language        = "SQL"
      description     = "Procedure to update user statistics"
      definition_body = <<-SQL
        BEGIN
          UPDATE `${var.project_id}.${var.environment}_analytics_dataset.users`
          SET updated_at = CURRENT_TIMESTAMP()
          WHERE id = user_id;
        END
      SQL
      arguments = [
        {
          name      = "user_id"
          data_type = jsonencode({"type" = "INTEGER"})
          mode      = "IN"
        }
      ]
    },
    {
      routine_id      = "get_user_transactions"
      routine_type    = "TABLE_VALUED_FUNCTION"
      language        = "SQL"
      description     = "Table-valued function to get user transactions"
      definition_body = <<-SQL
        SELECT *
        FROM `${var.project_id}.${var.environment}_analytics_dataset.transactions`
        WHERE user_id = input_user_id
        ORDER BY transaction_date DESC
      SQL
      arguments = [
        {
          name      = "input_user_id"
          data_type = jsonencode({"type" = "INTEGER"})
        }
      ]
    }
  ]

  # IAM bindings (only if emails are specified)
  dataset_iam_bindings = merge(
    var.readonly_group_email != null && var.service_account_email != null ? {
      "roles/bigquery.dataViewer" = compact([
        var.readonly_group_email != null ? "group:${var.readonly_group_email}" : null,
        var.service_account_email != null ? "serviceAccount:${var.service_account_email}" : null
      ])
    } : {},
    var.data_team_group_email != null ? {
      "roles/bigquery.jobUser" = [
        "group:${var.data_team_group_email}"
      ]
    } : {}
  )

  # IAM members with conditions (only if user email is specified)
  dataset_iam_members = var.conditional_user_email != null ? {
    "conditional_viewer" = {
      role   = "roles/bigquery.dataViewer"
      member = "user:${var.conditional_user_email}"
      condition = {
        title      = "Time-based access"
        description = "Access only during business hours"
        expression = "request.time.getHours() >= 9 && request.time.getHours() < 17"
      }
    }
  } : {}

  # Authorized views from other datasets
  authorized_views = [
    {
      project_id = var.project_id
      dataset_id = "${var.environment}_reporting_dataset"
      table_id   = "user_summary_view"
    }
  ]

  # Authorized datasets
  authorized_datasets = [
    {
      project_id   = var.project_id
      dataset_id   = "${var.environment}_shared_dataset"
      target_types = ["VIEWS"]
    }
  ]
}

# =============================================================================
# Outputs
# =============================================================================

output "dataset_info" {
  description = "Information about the created BigQuery dataset"
  value = {
    dataset_id   = module.bigquery_complete.dataset_id
    dataset_name = module.bigquery_complete.dataset_name
    location     = module.bigquery_complete.dataset_location
    project      = module.bigquery_complete.dataset_project
    self_link    = module.bigquery_complete.dataset_self_link
  }
}

output "tables_info" {
  description = "Information about created tables"
  value = {
    table_ids   = module.bigquery_complete.table_ids
    table_names = module.bigquery_complete.table_names
    table_fqns  = module.bigquery_complete.table_fqns
  }
}

output "views_info" {
  description = "Information about created views"
  value = {
    view_ids   = module.bigquery_complete.view_ids
    view_names = module.bigquery_complete.view_names
  }
}

output "external_tables_info" {
  description = "Information about external tables"
  value = {
    external_table_ids           = module.bigquery_complete.external_table_ids
    external_table_names         = module.bigquery_complete.external_table_names
    external_table_source_formats = module.bigquery_complete.external_table_source_formats
  }
}

output "routines_info" {
  description = "Information about created routines"
  value = {
    routine_ids   = module.bigquery_complete.routine_ids
    routine_types = module.bigquery_complete.routine_types
  }
}

output "summary" {
  description = "Summary of all created resources"
  value       = module.bigquery_complete.summary
}