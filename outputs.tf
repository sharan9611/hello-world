# =============================================================================
# GCP BigQuery Terraform Module Outputs
# Comprehensive outputs for all BigQuery resources and their attributes
# =============================================================================

# =============================================================================
# Dataset Outputs
# =============================================================================

output "dataset_id" {
  description = "The ID of the BigQuery dataset"
  value       = google_bigquery_dataset.main.dataset_id
}

output "dataset_name" {
  description = "The friendly name of the BigQuery dataset"
  value       = google_bigquery_dataset.main.friendly_name
}

output "dataset_location" {
  description = "The location of the BigQuery dataset"
  value       = google_bigquery_dataset.main.location
}

output "dataset_project" {
  description = "The project ID where the BigQuery dataset is created"
  value       = google_bigquery_dataset.main.project
}

output "dataset_creation_time" {
  description = "The time when this dataset was created, in milliseconds since the epoch"
  value       = google_bigquery_dataset.main.creation_time
}

output "dataset_last_modified_time" {
  description = "The date when this dataset was last modified, in milliseconds since the epoch"
  value       = google_bigquery_dataset.main.last_modified_time
}

output "dataset_self_link" {
  description = "The URI of the created BigQuery dataset"
  value       = google_bigquery_dataset.main.self_link
}

output "dataset_etag" {
  description = "A hash of the dataset resource"
  value       = google_bigquery_dataset.main.etag
}

output "dataset_labels" {
  description = "The labels associated with the BigQuery dataset"
  value       = google_bigquery_dataset.main.labels
}

output "bigquery_dataset" {
  description = "The complete BigQuery dataset resource"
  value       = google_bigquery_dataset.main
  sensitive   = false
}

# =============================================================================
# Tables Outputs
# =============================================================================

output "table_ids" {
  description = "The IDs of the BigQuery tables"
  value       = [for table in google_bigquery_table.main : table.table_id]
}

output "table_names" {
  description = "The friendly names of the BigQuery tables"
  value       = [for table in google_bigquery_table.main : table.friendly_name]
}

output "table_self_links" {
  description = "The URIs of the BigQuery tables"
  value       = [for table in google_bigquery_table.main : table.self_link]
}

output "table_schemas" {
  description = "The schemas of the BigQuery tables"
  value       = { for k, table in google_bigquery_table.main : k => table.schema }
}

output "table_creation_times" {
  description = "The creation times of the BigQuery tables"
  value       = { for k, table in google_bigquery_table.main : k => table.creation_time }
}

output "table_last_modified_times" {
  description = "The last modified times of the BigQuery tables"
  value       = { for k, table in google_bigquery_table.main : k => table.last_modified_time }
}

output "table_num_bytes" {
  description = "The size of the BigQuery tables in bytes"
  value       = { for k, table in google_bigquery_table.main : k => table.num_bytes }
}

output "table_num_rows" {
  description = "The number of rows in the BigQuery tables"
  value       = { for k, table in google_bigquery_table.main : k => table.num_rows }
}

output "table_types" {
  description = "The types of the BigQuery tables"
  value       = { for k, table in google_bigquery_table.main : k => table.type }
}

output "table_fqns" {
  description = "Fully qualified names for the tables"
  value = {
    for k, table in google_bigquery_table.main :
    k => "${table.project}.${table.dataset_id}.${table.table_id}"
  }
}

output "bigquery_tables" {
  description = "Map of BigQuery table resources"
  value       = google_bigquery_table.main
  sensitive   = false
}

# =============================================================================
# Views Outputs
# =============================================================================

output "view_ids" {
  description = "The IDs of the BigQuery views"
  value       = [for view in google_bigquery_table.views : view.table_id]
}

output "view_names" {
  description = "The friendly names of the BigQuery views"
  value       = [for view in google_bigquery_table.views : view.friendly_name]
}

output "view_self_links" {
  description = "The URIs of the BigQuery views"
  value       = [for view in google_bigquery_table.views : view.self_link]
}

output "view_queries" {
  description = "The SQL queries of the BigQuery views"
  value       = { for k, view in google_bigquery_table.views : k => view.view[0].query }
}

output "view_creation_times" {
  description = "The creation times of the BigQuery views"
  value       = { for k, view in google_bigquery_table.views : k => view.creation_time }
}

output "view_last_modified_times" {
  description = "The last modified times of the BigQuery views"
  value       = { for k, view in google_bigquery_table.views : k => view.last_modified_time }
}

output "bigquery_views" {
  description = "Map of BigQuery view resources"
  value       = google_bigquery_table.views
  sensitive   = false
}

# =============================================================================
# Materialized Views Outputs
# =============================================================================

output "materialized_view_ids" {
  description = "The IDs of the BigQuery materialized views"
  value       = [for view in google_bigquery_table.materialized_views : view.table_id]
}

output "materialized_view_names" {
  description = "The friendly names of the BigQuery materialized views"
  value       = [for view in google_bigquery_table.materialized_views : view.friendly_name]
}

output "materialized_view_self_links" {
  description = "The URIs of the BigQuery materialized views"
  value       = [for view in google_bigquery_table.materialized_views : view.self_link]
}

output "materialized_view_queries" {
  description = "The SQL queries of the BigQuery materialized views"
  value       = { for k, view in google_bigquery_table.materialized_views : k => view.materialized_view[0].query }
}

output "materialized_view_creation_times" {
  description = "The creation times of the BigQuery materialized views"
  value       = { for k, view in google_bigquery_table.materialized_views : k => view.creation_time }
}

output "materialized_view_last_modified_times" {
  description = "The last modified times of the BigQuery materialized views"
  value       = { for k, view in google_bigquery_table.materialized_views : k => view.last_modified_time }
}

output "bigquery_materialized_views" {
  description = "Map of BigQuery materialized view resources"
  value       = google_bigquery_table.materialized_views
  sensitive   = false
}

# =============================================================================
# External Tables Outputs
# =============================================================================

output "external_table_ids" {
  description = "The IDs of the BigQuery external tables"
  value       = [for table in google_bigquery_table.external_tables : table.table_id]
}

output "external_table_names" {
  description = "The friendly names of the BigQuery external tables"
  value       = [for table in google_bigquery_table.external_tables : table.friendly_name]
}

output "external_table_self_links" {
  description = "The URIs of the BigQuery external tables"
  value       = [for table in google_bigquery_table.external_tables : table.self_link]
}

output "external_table_source_uris" {
  description = "The source URIs of the BigQuery external tables"
  value       = { for k, table in google_bigquery_table.external_tables : k => table.external_data_configuration[0].source_uris }
}

output "external_table_source_formats" {
  description = "The source formats of the BigQuery external tables"
  value       = { for k, table in google_bigquery_table.external_tables : k => table.external_data_configuration[0].source_format }
}

output "external_table_creation_times" {
  description = "The creation times of the BigQuery external tables"
  value       = { for k, table in google_bigquery_table.external_tables : k => table.creation_time }
}

output "external_table_last_modified_times" {
  description = "The last modified times of the BigQuery external tables"
  value       = { for k, table in google_bigquery_table.external_tables : k => table.last_modified_time }
}

output "bigquery_external_tables" {
  description = "Map of BigQuery external table resources"
  value       = google_bigquery_table.external_tables
  sensitive   = false
}

# =============================================================================
# Routines Outputs
# =============================================================================

output "routine_ids" {
  description = "The IDs of the BigQuery routines"
  value       = [for routine in google_bigquery_routine.main : routine.routine_id]
}

output "routine_types" {
  description = "The types of the BigQuery routines"
  value       = { for k, routine in google_bigquery_routine.main : k => routine.routine_type }
}

output "routine_languages" {
  description = "The languages of the BigQuery routines"
  value       = { for k, routine in google_bigquery_routine.main : k => routine.language }
}

output "routine_creation_times" {
  description = "The creation times of the BigQuery routines"
  value       = { for k, routine in google_bigquery_routine.main : k => routine.creation_time }
}

output "routine_last_modified_times" {
  description = "The last modified times of the BigQuery routines"
  value       = { for k, routine in google_bigquery_routine.main : k => routine.last_modified_time }
}

output "bigquery_routines" {
  description = "Map of BigQuery routine resources"
  value       = google_bigquery_routine.main
  sensitive   = false
}

# =============================================================================
# IAM Outputs
# =============================================================================

output "dataset_iam_bindings" {
  description = "The IAM bindings for the BigQuery dataset"
  value       = google_bigquery_dataset_iam_binding.bindings
  sensitive   = false
}

output "dataset_iam_members" {
  description = "The IAM members for the BigQuery dataset"
  value       = google_bigquery_dataset_iam_member.members
  sensitive   = false
}

# =============================================================================
# Access Control Outputs
# =============================================================================

output "authorized_views" {
  description = "The authorized views for the BigQuery dataset"
  value       = google_bigquery_dataset_access.authorized_views
  sensitive   = false
}

output "authorized_datasets" {
  description = "The authorized datasets for the BigQuery dataset"
  value       = google_bigquery_dataset_access.authorized_datasets
  sensitive   = false
}

# =============================================================================
# Environment Variables (for compatibility with existing modules)
# =============================================================================

output "env_vars" {
  description = "Exported environment variables for BigQuery resources"
  value = {
    DATASET_ID       = google_bigquery_dataset.main.dataset_id
    DATASET_LOCATION = google_bigquery_dataset.main.location
    PROJECT_ID       = google_bigquery_dataset.main.project
  }
}

# =============================================================================
# Summary Outputs
# =============================================================================

output "summary" {
  description = "Summary of all created BigQuery resources"
  value = {
    dataset = {
      id       = google_bigquery_dataset.main.dataset_id
      name     = google_bigquery_dataset.main.friendly_name
      location = google_bigquery_dataset.main.location
      project  = google_bigquery_dataset.main.project
    }
    tables_count              = length(google_bigquery_table.main)
    views_count               = length(google_bigquery_table.views)
    materialized_views_count  = length(google_bigquery_table.materialized_views)
    external_tables_count     = length(google_bigquery_table.external_tables)
    routines_count            = length(google_bigquery_routine.main)
    iam_bindings_count        = length(google_bigquery_dataset_iam_binding.bindings)
    iam_members_count         = length(google_bigquery_dataset_iam_member.members)
    authorized_views_count    = length(google_bigquery_dataset_access.authorized_views)
    authorized_datasets_count = length(google_bigquery_dataset_access.authorized_datasets)
  }
}