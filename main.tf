# =============================================================================
# GCP BigQuery Terraform Module
# Comprehensive BigQuery module with all configurations from Terraform Registry
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
# Local Values
# =============================================================================

locals {
  # Flatten tables for for_each iteration
  tables_map = {
    for table in var.tables : table.table_id => table
  }

  # Flatten views for for_each iteration
  views_map = {
    for view in var.views : view.view_id => view
  }

  # Flatten materialized views for for_each iteration
  materialized_views_map = {
    for view in var.materialized_views : view.view_id => view
  }

  # Flatten external tables for for_each iteration
  external_tables_map = {
    for table in var.external_tables : table.table_id => table
  }

  # Flatten routines for for_each iteration
  routines_map = {
    for routine in var.routines : routine.routine_id => routine
  }
}

# =============================================================================
# BigQuery Dataset
# =============================================================================

resource "google_bigquery_dataset" "main" {
  dataset_id                      = var.dataset_id
  friendly_name                   = var.dataset_name
  description                     = var.description
  location                        = var.location
  project                         = var.project_id
  delete_contents_on_destroy      = var.delete_contents_on_destroy
  default_table_expiration_ms     = var.default_table_expiration_ms
  default_partition_expiration_ms = var.default_partition_expiration_ms
  labels                          = var.dataset_labels
  max_time_travel_hours           = var.max_time_travel_hours
  storage_billing_model           = var.storage_billing_model
  is_case_insensitive             = var.is_case_insensitive

  # Default encryption configuration
  dynamic "default_encryption_configuration" {
    for_each = var.encryption_key != null ? [1] : []
    content {
      kms_key_name = var.encryption_key
    }
  }

  # Access controls
  dynamic "access" {
    for_each = var.access
    content {
      role          = lookup(access.value, "role", null)
      user_by_email = lookup(access.value, "user_by_email", null)
      group_by_email = lookup(access.value, "group_by_email", null)
      domain        = lookup(access.value, "domain", null)
      special_group = lookup(access.value, "special_group", null)
      iam_member    = lookup(access.value, "iam_member", null)

      # View access
      dynamic "view" {
        for_each = lookup(access.value, "view", null) != null ? [access.value.view] : []
        content {
          project_id = view.value.project_id
          dataset_id = view.value.dataset_id
          table_id   = view.value.table_id
        }
      }

      # Dataset access
      dynamic "dataset" {
        for_each = lookup(access.value, "dataset", null) != null ? [access.value.dataset] : []
        content {
          dataset {
            project_id = dataset.value.project_id
            dataset_id = dataset.value.dataset_id
          }
          target_types = dataset.value.target_types
        }
      }

      # Routine access
      dynamic "routine" {
        for_each = lookup(access.value, "routine", null) != null ? [access.value.routine] : []
        content {
          project_id = routine.value.project_id
          dataset_id = routine.value.dataset_id
          routine_id = routine.value.routine_id
        }
      }
    }
  }

  # External dataset reference
  dynamic "external_dataset_reference" {
    for_each = var.external_dataset_reference != null ? [var.external_dataset_reference] : []
    content {
      external_source = external_dataset_reference.value.external_source
      connection      = external_dataset_reference.value.connection
    }
  }

  # Resource tags
  dynamic "resource_tags" {
    for_each = var.resource_tags
    content {
      key   = resource_tags.key
      value = resource_tags.value
    }
  }
}

# =============================================================================
# BigQuery Tables
# =============================================================================

resource "google_bigquery_table" "main" {
  for_each = local.tables_map

  dataset_id          = google_bigquery_dataset.main.dataset_id
  table_id            = each.value.table_id
  project             = var.project_id
  friendly_name       = lookup(each.value, "table_name", each.value.table_id)
  description         = lookup(each.value, "description", null)
  labels              = lookup(each.value, "labels", {})
  schema              = each.value.schema
  clustering          = lookup(each.value, "clustering", [])
  expiration_time     = lookup(each.value, "expiration_time", null)
  deletion_protection = lookup(each.value, "deletion_protection", var.deletion_protection)
  require_partition_filter = lookup(each.value, "require_partition_filter", null)
  max_staleness       = lookup(each.value, "max_staleness", null)

  # Time partitioning
  dynamic "time_partitioning" {
    for_each = lookup(each.value, "time_partitioning", null) != null ? [each.value.time_partitioning] : []
    content {
      type                     = time_partitioning.value.type
      expiration_ms            = lookup(time_partitioning.value, "expiration_ms", null)
      field                    = lookup(time_partitioning.value, "field", null)
      require_partition_filter = lookup(time_partitioning.value, "require_partition_filter", null)
    }
  }

  # Range partitioning
  dynamic "range_partitioning" {
    for_each = lookup(each.value, "range_partitioning", null) != null ? [each.value.range_partitioning] : []
    content {
      field = range_partitioning.value.field
      range {
        start    = range_partitioning.value.range.start
        end      = range_partitioning.value.range.end
        interval = range_partitioning.value.range.interval
      }
    }
  }

  # Encryption configuration
  dynamic "encryption_configuration" {
    for_each = lookup(each.value, "encryption_key", var.encryption_key) != null ? [1] : []
    content {
      kms_key_name = lookup(each.value, "encryption_key", var.encryption_key)
    }
  }

  # Table constraints
  dynamic "table_constraints" {
    for_each = lookup(each.value, "table_constraints", null) != null ? [each.value.table_constraints] : []
    content {
      # Primary key
      dynamic "primary_key" {
        for_each = lookup(table_constraints.value, "primary_key", null) != null ? [table_constraints.value.primary_key] : []
        content {
          columns = primary_key.value.columns
        }
      }

      # Foreign keys
      dynamic "foreign_keys" {
        for_each = lookup(table_constraints.value, "foreign_keys", [])
        content {
          name = lookup(foreign_keys.value, "name", null)
          column_references {
            referencing_columns = foreign_keys.value.column_references.referencing_columns
            referenced_table {
              project_id = foreign_keys.value.column_references.referenced_table.project_id
              dataset_id = foreign_keys.value.column_references.referenced_table.dataset_id
              table_id   = foreign_keys.value.column_references.referenced_table.table_id
            }
            referenced_columns = foreign_keys.value.column_references.referenced_columns
          }
        }
      }
    }
  }

  # Table replication info
  dynamic "table_replication_info" {
    for_each = lookup(each.value, "table_replication_info", null) != null ? [each.value.table_replication_info] : []
    content {
      source_project_id = table_replication_info.value.source_project_id
      source_dataset_id = table_replication_info.value.source_dataset_id
      source_table_id   = table_replication_info.value.source_table_id
      replication_interval_ms = lookup(table_replication_info.value, "replication_interval_ms", null)
    }
  }

  depends_on = [google_bigquery_dataset.main]
}

# =============================================================================
# BigQuery Views
# =============================================================================

resource "google_bigquery_table" "views" {
  for_each = local.views_map

  dataset_id    = google_bigquery_dataset.main.dataset_id
  table_id      = each.value.view_id
  project       = var.project_id
  friendly_name = lookup(each.value, "view_name", each.value.view_id)
  description   = lookup(each.value, "description", null)
  labels        = lookup(each.value, "labels", {})

  view {
    query          = each.value.query
    use_legacy_sql = lookup(each.value, "use_legacy_sql", false)
  }

  # Encryption configuration
  dynamic "encryption_configuration" {
    for_each = lookup(each.value, "encryption_key", var.encryption_key) != null ? [1] : []
    content {
      kms_key_name = lookup(each.value, "encryption_key", var.encryption_key)
    }
  }

  depends_on = [
    google_bigquery_dataset.main,
    google_bigquery_table.main
  ]
}

# =============================================================================
# BigQuery Materialized Views
# =============================================================================

resource "google_bigquery_table" "materialized_views" {
  for_each = local.materialized_views_map

  dataset_id          = google_bigquery_dataset.main.dataset_id
  table_id            = each.value.view_id
  project             = var.project_id
  friendly_name       = lookup(each.value, "view_name", each.value.view_id)
  description         = lookup(each.value, "description", null)
  labels              = lookup(each.value, "labels", {})
  clustering          = lookup(each.value, "clustering", [])
  expiration_time     = lookup(each.value, "expiration_time", null)
  max_staleness       = lookup(each.value, "max_staleness", null)

  materialized_view {
    query                = each.value.query
    enable_refresh       = lookup(each.value, "enable_refresh", true)
    refresh_interval_ms  = lookup(each.value, "refresh_interval_ms", null)
    allow_non_incremental_definition = lookup(each.value, "allow_non_incremental_definition", null)
  }

  # Time partitioning
  dynamic "time_partitioning" {
    for_each = lookup(each.value, "time_partitioning", null) != null ? [each.value.time_partitioning] : []
    content {
      type                     = time_partitioning.value.type
      expiration_ms            = lookup(time_partitioning.value, "expiration_ms", null)
      field                    = lookup(time_partitioning.value, "field", null)
      require_partition_filter = lookup(time_partitioning.value, "require_partition_filter", null)
    }
  }

  # Range partitioning
  dynamic "range_partitioning" {
    for_each = lookup(each.value, "range_partitioning", null) != null ? [each.value.range_partitioning] : []
    content {
      field = range_partitioning.value.field
      range {
        start    = range_partitioning.value.range.start
        end      = range_partitioning.value.range.end
        interval = range_partitioning.value.range.interval
      }
    }
  }

  # Encryption configuration
  dynamic "encryption_configuration" {
    for_each = lookup(each.value, "encryption_key", var.encryption_key) != null ? [1] : []
    content {
      kms_key_name = lookup(each.value, "encryption_key", var.encryption_key)
    }
  }

  depends_on = [
    google_bigquery_dataset.main,
    google_bigquery_table.main
  ]
}

# =============================================================================
# BigQuery External Tables
# =============================================================================

resource "google_bigquery_table" "external_tables" {
  for_each = local.external_tables_map

  dataset_id          = google_bigquery_dataset.main.dataset_id
  table_id            = each.value.table_id
  project             = var.project_id
  friendly_name       = lookup(each.value, "table_name", each.value.table_id)
  description         = lookup(each.value, "description", null)
  labels              = lookup(each.value, "labels", {})
  schema              = lookup(each.value, "schema", null)
  expiration_time     = lookup(each.value, "expiration_time", null)
  deletion_protection = lookup(each.value, "deletion_protection", var.deletion_protection)
  max_staleness       = lookup(each.value, "max_staleness", null)

  external_data_configuration {
    autodetect            = lookup(each.value, "autodetect", false)
    compression           = lookup(each.value, "compression", "NONE")
    ignore_unknown_values = lookup(each.value, "ignore_unknown_values", false)
    max_bad_records       = lookup(each.value, "max_bad_records", 0)
    source_format         = each.value.source_format
    source_uris           = each.value.source_uris
    connection_id         = lookup(each.value, "connection_id", null)
    reference_file_schema_uri = lookup(each.value, "reference_file_schema_uri", null)

    # CSV options
    dynamic "csv_options" {
      for_each = lookup(each.value, "csv_options", null) != null ? [each.value.csv_options] : []
      content {
        quote                 = lookup(csv_options.value, "quote", "\"")
        allow_jagged_rows     = lookup(csv_options.value, "allow_jagged_rows", false)
        allow_quoted_newlines = lookup(csv_options.value, "allow_quoted_newlines", false)
        encoding              = lookup(csv_options.value, "encoding", "UTF-8")
        field_delimiter       = lookup(csv_options.value, "field_delimiter", ",")
        skip_leading_rows     = lookup(csv_options.value, "skip_leading_rows", 0)
        null_marker           = lookup(csv_options.value, "null_marker", null)
      }
    }

    # Google Sheets options
    dynamic "google_sheets_options" {
      for_each = lookup(each.value, "google_sheets_options", null) != null ? [each.value.google_sheets_options] : []
      content {
        range             = lookup(google_sheets_options.value, "range", null)
        skip_leading_rows = lookup(google_sheets_options.value, "skip_leading_rows", 0)
      }
    }

    # Hive partitioning options
    dynamic "hive_partitioning_options" {
      for_each = lookup(each.value, "hive_partitioning_options", null) != null ? [each.value.hive_partitioning_options] : []
      content {
        mode                     = lookup(hive_partitioning_options.value, "mode", "AUTO")
        source_uri_prefix        = lookup(hive_partitioning_options.value, "source_uri_prefix", null)
        require_partition_filter = lookup(hive_partitioning_options.value, "require_partition_filter", null)
      }
    }

    # Parquet options
    dynamic "parquet_options" {
      for_each = lookup(each.value, "parquet_options", null) != null ? [each.value.parquet_options] : []
      content {
        enum_as_string        = lookup(parquet_options.value, "enum_as_string", null)
        enable_list_inference = lookup(parquet_options.value, "enable_list_inference", null)
      }
    }

    # Avro options
    dynamic "avro_options" {
      for_each = lookup(each.value, "avro_options", null) != null ? [each.value.avro_options] : []
      content {
        use_avro_logical_types = lookup(avro_options.value, "use_avro_logical_types", null)
      }
    }

    # JSON options
    dynamic "json_options" {
      for_each = lookup(each.value, "json_options", null) != null ? [each.value.json_options] : []
      content {
        encoding = lookup(json_options.value, "encoding", "UTF-8")
      }
    }

    # Bigtable options
    dynamic "bigtable_options" {
      for_each = lookup(each.value, "bigtable_options", null) != null ? [each.value.bigtable_options] : []
      content {
        ignore_unspecified_column_families = lookup(bigtable_options.value, "ignore_unspecified_column_families", null)
        read_rowkey_as_string              = lookup(bigtable_options.value, "read_rowkey_as_string", null)
        output_column_families_as_json     = lookup(bigtable_options.value, "output_column_families_as_json", null)

        # Column families
        dynamic "column_family" {
          for_each = lookup(bigtable_options.value, "column_families", [])
          content {
            family_id      = column_family.value.family_id
            type           = lookup(column_family.value, "type", null)
            encoding       = lookup(column_family.value, "encoding", null)
            only_read_latest = lookup(column_family.value, "only_read_latest", null)

            # Columns
            dynamic "column" {
              for_each = lookup(column_family.value, "columns", [])
              content {
                qualifier_string = lookup(column.value, "qualifier_string", null)
                qualifier_encoded = lookup(column.value, "qualifier_encoded", null)
                field_name       = lookup(column.value, "field_name", null)
                type            = lookup(column.value, "type", null)
                encoding        = lookup(column.value, "encoding", null)
                only_read_latest = lookup(column.value, "only_read_latest", null)
              }
            }
          }
        }
      }
    }
  }

  # Encryption configuration
  dynamic "encryption_configuration" {
    for_each = lookup(each.value, "encryption_key", var.encryption_key) != null ? [1] : []
    content {
      kms_key_name = lookup(each.value, "encryption_key", var.encryption_key)
    }
  }

  depends_on = [google_bigquery_dataset.main]
}

# =============================================================================
# BigQuery Routines (Functions and Procedures)
# =============================================================================

resource "google_bigquery_routine" "main" {
  for_each = local.routines_map

  dataset_id      = google_bigquery_dataset.main.dataset_id
  routine_id      = each.value.routine_id
  project         = var.project_id
  routine_type    = each.value.routine_type
  language        = lookup(each.value, "language", "SQL")
  definition_body = each.value.definition_body
  return_type     = lookup(each.value, "return_type", null)
  return_table_type = lookup(each.value, "return_table_type", null)
  description     = lookup(each.value, "description", null)
  determinism_level = lookup(each.value, "determinism_level", null)
  imported_libraries = lookup(each.value, "imported_libraries", [])
  remote_function_options = lookup(each.value, "remote_function_options", null)
  spark_options   = lookup(each.value, "spark_options", null)

  # Arguments
  dynamic "arguments" {
    for_each = lookup(each.value, "arguments", [])
    content {
      name            = lookup(arguments.value, "name", null)
      data_type       = lookup(arguments.value, "data_type", null)
      argument_kind   = lookup(arguments.value, "argument_kind", "FIXED_TYPE")
      mode           = lookup(arguments.value, "mode", null)
    }
  }

  depends_on = [google_bigquery_dataset.main]
}

# =============================================================================
# BigQuery Dataset IAM Bindings (Optional)
# =============================================================================

resource "google_bigquery_dataset_iam_binding" "bindings" {
  for_each = var.dataset_iam_bindings

  dataset_id = google_bigquery_dataset.main.dataset_id
  project    = var.project_id
  role       = each.key
  members    = each.value

  depends_on = [google_bigquery_dataset.main]
}

# =============================================================================
# BigQuery Dataset IAM Members (Optional)
# =============================================================================

resource "google_bigquery_dataset_iam_member" "members" {
  for_each = var.dataset_iam_members

  dataset_id = google_bigquery_dataset.main.dataset_id
  project    = var.project_id
  role       = each.value.role
  member     = each.value.member

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = lookup(condition.value, "description", null)
      expression  = condition.value.expression
    }
  }

  depends_on = [google_bigquery_dataset.main]
}

# =============================================================================
# BigQuery Authorized Views (Optional)
# =============================================================================

resource "google_bigquery_dataset_access" "authorized_views" {
  for_each = {
    for idx, view in var.authorized_views : "${view.project_id}_${view.dataset_id}_${view.table_id}" => view
  }

  dataset_id = google_bigquery_dataset.main.dataset_id
  project    = var.project_id

  view {
    project_id = each.value.project_id
    dataset_id = each.value.dataset_id
    table_id   = each.value.table_id
  }

  depends_on = [google_bigquery_dataset.main]
}

# =============================================================================
# BigQuery Authorized Datasets (Optional)
# =============================================================================

resource "google_bigquery_dataset_access" "authorized_datasets" {
  for_each = {
    for idx, dataset in var.authorized_datasets : "${dataset.project_id}_${dataset.dataset_id}" => dataset
  }

  dataset_id = google_bigquery_dataset.main.dataset_id
  project    = var.project_id

  dataset {
    dataset {
      project_id = each.value.project_id
      dataset_id = each.value.dataset_id
    }
    target_types = lookup(each.value, "target_types", ["VIEWS"])
  }

  depends_on = [google_bigquery_dataset.main]
}