# =============================================================================
# GCP BigQuery Terraform Module Variables
# Comprehensive variable definitions for all BigQuery configurations
# =============================================================================

# =============================================================================
# Required Variables
# =============================================================================

variable "project_id" {
  description = "The ID of the GCP project where the BigQuery dataset will be created"
  type        = string
}

variable "dataset_id" {
  description = "A unique ID for the BigQuery dataset being provisioned"
  type        = string
}

# =============================================================================
# Dataset Configuration Variables
# =============================================================================

variable "dataset_name" {
  description = "A descriptive friendly name for the BigQuery dataset"
  type        = string
  default     = null
}

variable "description" {
  description = "A user-friendly description of the BigQuery dataset"
  type        = string
  default     = null
}

variable "location" {
  description = "The geographic location where the BigQuery dataset should reside. Options: US, EU, or specific regions like us-central1"
  type        = string
  default     = "US"
}

variable "dataset_labels" {
  description = "A mapping of labels to assign to the BigQuery dataset"
  type        = map(string)
  default     = {}
}

variable "delete_contents_on_destroy" {
  description = "If set to true, delete all the tables in the dataset when destroying the resource; otherwise, destroying the resource will fail if tables are present"
  type        = bool
  default     = false
}

variable "default_table_expiration_ms" {
  description = "The default lifetime of all tables in the dataset, in milliseconds"
  type        = number
  default     = null
}

variable "default_partition_expiration_ms" {
  description = "The default partition expiration for all partitioned tables in the dataset, in milliseconds"
  type        = number
  default     = null
}

variable "max_time_travel_hours" {
  description = "Defines the time travel window in hours. The value can be from 48 to 168 hours (2 to 7 days)"
  type        = number
  default     = null
}

variable "storage_billing_model" {
  description = "Specifies the storage billing model for the dataset. Set to LOGICAL to use logical bytes for storage billing, or to PHYSICAL to use physical bytes"
  type        = string
  default     = null
  validation {
    condition     = var.storage_billing_model == null || contains(["LOGICAL", "PHYSICAL"], var.storage_billing_model)
    error_message = "Storage billing model must be either LOGICAL or PHYSICAL."
  }
}

variable "is_case_insensitive" {
  description = "TRUE if the dataset and its table names are case-insensitive, otherwise FALSE"
  type        = bool
  default     = false
}

variable "encryption_key" {
  description = "Default encryption key to apply to the dataset. Defaults to null (Google-managed)"
  type        = string
  default     = null
}

variable "resource_tags" {
  description = "A mapping of resource tags to assign to the BigQuery dataset"
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "Whether or not to allow deletion of tables and external tables defined by this module. Can be overridden by table-level deletion_protection configuration"
  type        = bool
  default     = false
}

# =============================================================================
# Dataset Access Control Variables
# =============================================================================

variable "access" {
  description = "An array of objects that define dataset access for one or more entities"
  type = list(object({
    role           = optional(string)
    user_by_email  = optional(string)
    group_by_email = optional(string)
    domain         = optional(string)
    special_group  = optional(string)
    iam_member     = optional(string)
    view = optional(object({
      project_id = string
      dataset_id = string
      table_id   = string
    }))
    dataset = optional(object({
      project_id   = string
      dataset_id   = string
      target_types = list(string)
    }))
    routine = optional(object({
      project_id = string
      dataset_id = string
      routine_id = string
    }))
  }))
  default = [
    {
      role          = "roles/bigquery.dataOwner"
      special_group = "projectOwners"
    }
  ]
}

variable "authorized_views" {
  description = "An array of views to give authorize for the dataset"
  type = list(object({
    project_id = string
    dataset_id = string
    table_id   = string
  }))
  default = []
}

variable "authorized_datasets" {
  description = "An array of datasets to be authorized on the dataset"
  type = list(object({
    project_id   = string
    dataset_id   = string
    target_types = optional(list(string), ["VIEWS"])
  }))
  default = []
}

variable "external_dataset_reference" {
  description = "Information required to query tables in this dataset as a federated data source"
  type = object({
    external_source = string
    connection      = string
  })
  default = null
}

# =============================================================================
# IAM Variables
# =============================================================================

variable "dataset_iam_bindings" {
  description = "Map of IAM bindings for the dataset. Keys are roles, values are lists of members"
  type        = map(list(string))
  default     = {}
}

variable "dataset_iam_members" {
  description = "Map of IAM members for the dataset"
  type = map(object({
    role   = string
    member = string
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = {}
}

# =============================================================================
# Tables Configuration Variables
# =============================================================================

variable "tables" {
  description = "A list of objects which include table_id, schema, clustering, time_partitioning, range_partitioning, expiration_time, deletion_protection and labels"
  type = list(object({
    table_id                 = string
    table_name               = optional(string)
    description              = optional(string)
    schema                   = string
    clustering               = optional(list(string), [])
    require_partition_filter = optional(bool)
    deletion_protection      = optional(bool)
    expiration_time          = optional(string)
    max_staleness            = optional(string)
    labels                   = optional(map(string), {})
    encryption_key           = optional(string)
    time_partitioning = optional(object({
      type                     = string
      field                    = optional(string)
      require_partition_filter = optional(bool)
      expiration_ms            = optional(string)
    }))
    range_partitioning = optional(object({
      field = string
      range = object({
        start    = string
        end      = string
        interval = string
      })
    }))
    table_constraints = optional(object({
      primary_key = optional(object({
        columns = list(string)
      }))
      foreign_keys = optional(list(object({
        name = optional(string)
        column_references = object({
          referencing_columns = list(string)
          referenced_table = object({
            project_id = string
            dataset_id = string
            table_id   = string
          })
          referenced_columns = list(string)
        })
      })), [])
    }))
    table_replication_info = optional(object({
      source_project_id       = string
      source_dataset_id       = string
      source_table_id         = string
      replication_interval_ms = optional(number)
    }))
  }))
  default = []
}

# =============================================================================
# Views Configuration Variables
# =============================================================================

variable "views" {
  description = "A list of objects which include view_id, query, use_legacy_sql, description and labels"
  type = list(object({
    view_id        = string
    view_name      = optional(string)
    description    = optional(string)
    query          = string
    use_legacy_sql = optional(bool, false)
    labels         = optional(map(string), {})
    encryption_key = optional(string)
  }))
  default = []
}

# =============================================================================
# Materialized Views Configuration Variables
# =============================================================================

variable "materialized_views" {
  description = "A list of objects which includes view_id, query, clustering, time_partitioning, range_partitioning, expiration_time and labels"
  type = list(object({
    view_id                          = string
    view_name                        = optional(string)
    description                      = optional(string)
    query                            = string
    enable_refresh                   = optional(bool, true)
    refresh_interval_ms              = optional(string)
    allow_non_incremental_definition = optional(bool)
    clustering                       = optional(list(string), [])
    expiration_time                  = optional(string)
    max_staleness                    = optional(string)
    labels                           = optional(map(string), {})
    encryption_key                   = optional(string)
    time_partitioning = optional(object({
      type                     = string
      field                    = optional(string)
      require_partition_filter = optional(bool)
      expiration_ms            = optional(string)
    }))
    range_partitioning = optional(object({
      field = string
      range = object({
        start    = string
        end      = string
        interval = string
      })
    }))
  }))
  default = []
}

# =============================================================================
# External Tables Configuration Variables
# =============================================================================

variable "external_tables" {
  description = "A list of objects which include table_id, expiration_time, external_data_configuration, and labels"
  type = list(object({
    table_id                  = string
    table_name                = optional(string)
    description               = optional(string)
    autodetect                = optional(bool, false)
    compression               = optional(string, "NONE")
    ignore_unknown_values     = optional(bool, false)
    max_bad_records           = optional(number, 0)
    schema                    = optional(string)
    source_format             = string
    source_uris               = list(string)
    connection_id             = optional(string)
    reference_file_schema_uri = optional(string)
    expiration_time           = optional(string)
    max_staleness             = optional(string)
    deletion_protection       = optional(bool)
    labels                    = optional(map(string), {})
    encryption_key            = optional(string)
    csv_options = optional(object({
      quote                 = optional(string, "\"")
      allow_jagged_rows     = optional(bool, false)
      allow_quoted_newlines = optional(bool, false)
      encoding              = optional(string, "UTF-8")
      field_delimiter       = optional(string, ",")
      skip_leading_rows     = optional(number, 0)
      null_marker           = optional(string)
    }))
    google_sheets_options = optional(object({
      range             = optional(string)
      skip_leading_rows = optional(number, 0)
    }))
    hive_partitioning_options = optional(object({
      mode                     = optional(string, "AUTO")
      source_uri_prefix        = optional(string)
      require_partition_filter = optional(bool)
    }))
    parquet_options = optional(object({
      enum_as_string        = optional(bool)
      enable_list_inference = optional(bool)
    }))
    avro_options = optional(object({
      use_avro_logical_types = optional(bool)
    }))
    json_options = optional(object({
      encoding = optional(string, "UTF-8")
    }))
    bigtable_options = optional(object({
      ignore_unspecified_column_families = optional(bool)
      read_rowkey_as_string              = optional(bool)
      output_column_families_as_json     = optional(bool)
      column_families = optional(list(object({
        family_id        = string
        type             = optional(string)
        encoding         = optional(string)
        only_read_latest = optional(bool)
        columns = optional(list(object({
          qualifier_string  = optional(string)
          qualifier_encoded = optional(string)
          field_name        = optional(string)
          type              = optional(string)
          encoding          = optional(string)
          only_read_latest  = optional(bool)
        })), [])
      })), [])
    }))
  }))
  default = []
}

# =============================================================================
# Routines Configuration Variables
# =============================================================================

variable "routines" {
  description = "A list of objects which include routine_id, routine_type, language, definition_body, return_type, description and arguments"
  type = list(object({
    routine_id              = string
    routine_type            = string
    language                = optional(string, "SQL")
    definition_body         = string
    return_type             = optional(string)
    return_table_type       = optional(string)
    description             = optional(string)
    determinism_level       = optional(string)
    imported_libraries      = optional(list(string), [])
    remote_function_options = optional(string)
    spark_options           = optional(string)
    arguments = optional(list(object({
      name          = optional(string)
      data_type     = optional(string)
      argument_kind = optional(string, "FIXED_TYPE")
      mode          = optional(string)
    })), [])
  }))
  default = []
  validation {
    condition = alltrue([
      for routine in var.routines :
      contains(["SCALAR_FUNCTION", "PROCEDURE", "TABLE_VALUED_FUNCTION"], routine.routine_type)
    ])
    error_message = "Routine type must be one of: SCALAR_FUNCTION, PROCEDURE, TABLE_VALUED_FUNCTION."
  }
  validation {
    condition = alltrue([
      for routine in var.routines :
      routine.language == null || contains(["SQL", "JAVASCRIPT", "PYTHON", "SCALA"], routine.language)
    ])
    error_message = "Language must be one of: SQL, JAVASCRIPT, PYTHON, SCALA."
  }
}