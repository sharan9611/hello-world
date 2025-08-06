# GCP BigQuery Terraform Module

A comprehensive Terraform module for creating and managing Google Cloud Platform BigQuery datasets and all related resources. This module provides complete coverage of BigQuery features including datasets, tables, views, materialized views, external tables, routines, and advanced configurations.

## Features

### 🗄️ **Dataset Management**
- Complete dataset lifecycle management
- Advanced configuration options (time travel, storage billing, case sensitivity)
- Comprehensive access control and IAM management
- Resource tagging and labeling
- Encryption configuration

### 📊 **Table Types**
- **Regular Tables**: Standard BigQuery tables with full schema support
- **Partitioned Tables**: Time-based and range partitioning
- **Clustered Tables**: Column-based clustering for performance
- **External Tables**: Integration with Cloud Storage, Bigtable, and other sources
- **Table Constraints**: Primary keys and foreign keys support

### 👁️ **Views and Materialized Views**
- Standard SQL views with legacy SQL support
- Materialized views with automatic refresh
- Partitioned and clustered materialized views
- View-based access control

### 🔧 **Routines**
- SQL and JavaScript functions
- Stored procedures
- Table-valued functions
- User-defined functions (UDFs)

### 🔐 **Security and Access Control**
- Fine-grained IAM policies
- Conditional IAM bindings
- Authorized views and datasets
- Row-level and column-level security support

### 📁 **External Data Sources**
- CSV files from Cloud Storage
- JSON and Avro files
- Google Sheets integration
- Bigtable external tables
- Parquet files with Hive partitioning

## Usage

### Basic Usage

```hcl
module "bigquery" {
  source = "path/to/this/module"

  project_id = "my-gcp-project"
  dataset_id = "analytics_dataset"
  
  dataset_name = "Analytics Dataset"
  description  = "Dataset for analytics workloads"
  location     = "US"
  
  tables = [
    {
      table_id = "users"
      schema = jsonencode([
        {
          name = "id"
          type = "INTEGER"
          mode = "REQUIRED"
        },
        {
          name = "name"
          type = "STRING"
          mode = "REQUIRED"
        },
        {
          name = "email"
          type = "STRING"
          mode = "NULLABLE"
        }
      ])
    }
  ]
}
```

### Advanced Usage with All Features

```hcl
module "bigquery_advanced" {
  source = "path/to/this/module"

  # Required variables
  project_id = "my-gcp-project"
  dataset_id = "advanced_analytics"

  # Dataset configuration
  dataset_name                    = "Advanced Analytics Dataset"
  description                     = "Comprehensive analytics dataset"
  location                        = "US"
  delete_contents_on_destroy      = true
  default_table_expiration_ms     = 7776000000  # 90 days
  default_partition_expiration_ms = 2592000000  # 30 days
  max_time_travel_hours          = 168         # 7 days
  storage_billing_model          = "LOGICAL"
  is_case_insensitive            = false
  
  dataset_labels = {
    environment = "production"
    team        = "data-engineering"
    cost_center = "analytics"
  }

  # Tables with partitioning and clustering
  tables = [
    {
      table_id    = "events"
      description = "Event tracking table with time partitioning"
      schema = jsonencode([
        {
          name = "event_id"
          type = "STRING"
          mode = "REQUIRED"
        },
        {
          name = "user_id"
          type = "INTEGER"
          mode = "REQUIRED"
        },
        {
          name = "event_timestamp"
          type = "TIMESTAMP"
          mode = "REQUIRED"
        },
        {
          name = "event_date"
          type = "DATE"
          mode = "REQUIRED"
        }
      ])
      clustering = ["user_id", "event_id"]
      time_partitioning = {
        type                     = "DAY"
        field                    = "event_date"
        require_partition_filter = true
        expiration_ms            = "2592000000"  # 30 days
      }
      deletion_protection = true
    }
  ]

  # Views
  views = [
    {
      view_id = "recent_events"
      query = <<-SQL
        SELECT *
        FROM `${var.project_id}.advanced_analytics.events`
        WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
      SQL
    }
  ]

  # Materialized views
  materialized_views = [
    {
      view_id             = "daily_event_stats"
      enable_refresh      = true
      refresh_interval_ms = "3600000"  # 1 hour
      query = <<-SQL
        SELECT
          event_date,
          COUNT(*) as event_count,
          COUNT(DISTINCT user_id) as unique_users
        FROM `${var.project_id}.advanced_analytics.events`
        GROUP BY event_date
      SQL
      time_partitioning = {
        type  = "DAY"
        field = "event_date"
      }
    }
  ]

  # External tables
  external_tables = [
    {
      table_id      = "external_logs"
      source_format = "CSV"
      source_uris   = ["gs://my-bucket/logs/*.csv"]
      autodetect    = true
      csv_options = {
        skip_leading_rows = 1
        field_delimiter   = ","
      }
    }
  ]

  # Routines
  routines = [
    {
      routine_id      = "calculate_metrics"
      routine_type    = "SCALAR_FUNCTION"
      language        = "SQL"
      definition_body = "value * multiplier"
      return_type     = jsonencode({"type" = "NUMERIC"})
      arguments = [
        {
          name      = "value"
          data_type = jsonencode({"type" = "NUMERIC"})
        },
        {
          name      = "multiplier"
          data_type = jsonencode({"type" = "NUMERIC"})
        }
      ]
    }
  ]

  # IAM configuration
  dataset_iam_bindings = {
    "roles/bigquery.dataViewer" = [
      "group:analytics-team@company.com",
      "serviceAccount:analytics-sa@project.iam.gserviceaccount.com"
    ]
  }
}
```

## Input Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `project_id` | The ID of the GCP project | `string` |
| `dataset_id` | Unique ID for the dataset | `string` |

### Dataset Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `dataset_name` | Friendly name for the dataset | `string` | `null` |
| `description` | Dataset description | `string` | `null` |
| `location` | Dataset location (US, EU, or region) | `string` | `"US"` |
| `dataset_labels` | Labels for the dataset | `map(string)` | `{}` |
| `delete_contents_on_destroy` | Delete tables when destroying dataset | `bool` | `false` |
| `default_table_expiration_ms` | Default table expiration in milliseconds | `number` | `null` |
| `default_partition_expiration_ms` | Default partition expiration in milliseconds | `number` | `null` |
| `max_time_travel_hours` | Time travel window (48-168 hours) | `number` | `null` |
| `storage_billing_model` | Storage billing model (LOGICAL/PHYSICAL) | `string` | `null` |
| `is_case_insensitive` | Case-insensitive dataset and table names | `bool` | `false` |
| `encryption_key` | KMS encryption key | `string` | `null` |
| `resource_tags` | Resource tags | `map(string)` | `{}` |
| `deletion_protection` | Prevent resource deletion | `bool` | `false` |

### Tables Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `tables` | List of table configurations | `list(object)` | `[]` |

#### Table Object Structure

```hcl
{
  table_id                 = string                    # Required
  table_name               = optional(string)          # Friendly name
  description              = optional(string)          # Table description
  schema                   = string                    # JSON schema
  clustering               = optional(list(string))    # Clustering columns
  require_partition_filter = optional(bool)            # Require partition filter
  deletion_protection      = optional(bool)            # Deletion protection
  expiration_time          = optional(string)          # Expiration timestamp
  max_staleness            = optional(string)          # Max staleness
  labels                   = optional(map(string))     # Table labels
  encryption_key           = optional(string)          # Table-specific encryption

  # Time partitioning
  time_partitioning = optional(object({
    type                     = string           # "DAY", "HOUR", "MONTH", "YEAR"
    field                    = optional(string) # Partitioning field
    require_partition_filter = optional(bool)   # Require partition filter
    expiration_ms            = optional(string) # Partition expiration
  }))

  # Range partitioning
  range_partitioning = optional(object({
    field = string                              # Partitioning field
    range = object({
      start    = string                         # Start value
      end      = string                         # End value
      interval = string                         # Interval
    })
  }))

  # Table constraints
  table_constraints = optional(object({
    primary_key = optional(object({
      columns = list(string)                    # Primary key columns
    }))
    foreign_keys = optional(list(object({
      name = optional(string)                   # Constraint name
      column_references = object({
        referencing_columns = list(string)      # Source columns
        referenced_table = object({
          project_id = string                   # Target project
          dataset_id = string                   # Target dataset
          table_id   = string                   # Target table
        })
        referenced_columns = list(string)       # Target columns
      })
    })))
  }))
}
```

### Views Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `views` | List of view configurations | `list(object)` | `[]` |

#### View Object Structure

```hcl
{
  view_id        = string                       # Required
  view_name      = optional(string)             # Friendly name
  description    = optional(string)             # View description
  query          = string                       # SQL query
  use_legacy_sql = optional(bool, false)        # Use legacy SQL
  labels         = optional(map(string))        # View labels
  encryption_key = optional(string)             # View-specific encryption
}
```

### External Tables Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `external_tables` | List of external table configurations | `list(object)` | `[]` |

#### External Table Object Structure

```hcl
{
  table_id                  = string                    # Required
  table_name                = optional(string)          # Friendly name
  description               = optional(string)          # Table description
  source_format             = string                    # CSV, JSON, AVRO, etc.
  source_uris               = list(string)              # Source URIs
  autodetect                = optional(bool, false)     # Auto-detect schema
  compression               = optional(string, "NONE")  # Compression type
  ignore_unknown_values     = optional(bool, false)     # Ignore unknown values
  max_bad_records           = optional(number, 0)       # Max bad records
  schema                    = optional(string)          # JSON schema
  connection_id             = optional(string)          # Connection ID
  reference_file_schema_uri = optional(string)          # Reference schema URI
  
  # Format-specific options
  csv_options = optional(object({
    quote                 = optional(string, "\"")      # Quote character
    allow_jagged_rows     = optional(bool, false)       # Allow jagged rows
    allow_quoted_newlines = optional(bool, false)       # Allow quoted newlines
    encoding              = optional(string, "UTF-8")   # File encoding
    field_delimiter       = optional(string, ",")       # Field delimiter
    skip_leading_rows     = optional(number, 0)         # Skip header rows
    null_marker           = optional(string)            # NULL marker
  }))

  google_sheets_options = optional(object({
    range             = optional(string)                # Sheet range
    skip_leading_rows = optional(number, 0)             # Skip header rows
  }))

  # Additional format options available for Parquet, Avro, JSON, Bigtable
}
```

## Outputs

### Dataset Outputs

| Name | Description |
|------|-------------|
| `dataset_id` | Dataset ID |
| `dataset_name` | Dataset friendly name |
| `dataset_location` | Dataset location |
| `dataset_project` | Project ID |
| `dataset_creation_time` | Creation timestamp |
| `dataset_self_link` | Dataset URI |
| `bigquery_dataset` | Complete dataset resource |

### Table Outputs

| Name | Description |
|------|-------------|
| `table_ids` | List of table IDs |
| `table_names` | List of table names |
| `table_fqns` | Fully qualified table names |
| `table_schemas` | Table schemas |
| `bigquery_tables` | Complete table resources |

### View Outputs

| Name | Description |
|------|-------------|
| `view_ids` | List of view IDs |
| `view_names` | List of view names |
| `view_queries` | View SQL queries |
| `bigquery_views` | Complete view resources |

### Summary Output

| Name | Description |
|------|-------------|
| `summary` | Summary of all created resources |

## Examples

### Simple Dataset with Tables

```hcl
module "simple_bigquery" {
  source = "path/to/this/module"

  project_id = "my-project"
  dataset_id = "my_dataset"
  
  tables = [
    {
      table_id = "users"
      schema = jsonencode([
        {name = "id", type = "INTEGER", mode = "REQUIRED"},
        {name = "name", type = "STRING", mode = "REQUIRED"}
      ])
    }
  ]
}
```

### Partitioned Table with Clustering

```hcl
module "partitioned_bigquery" {
  source = "path/to/this/module"

  project_id = "my-project"
  dataset_id = "events_dataset"
  
  tables = [
    {
      table_id = "events"
      schema = jsonencode([
        {name = "event_id", type = "STRING", mode = "REQUIRED"},
        {name = "user_id", type = "INTEGER", mode = "REQUIRED"},
        {name = "event_date", type = "DATE", mode = "REQUIRED"}
      ])
      clustering = ["user_id"]
      time_partitioning = {
        type                     = "DAY"
        field                    = "event_date"
        require_partition_filter = true
      }
    }
  ]
}
```

### External Table from Cloud Storage

```hcl
module "external_bigquery" {
  source = "path/to/this/module"

  project_id = "my-project"
  dataset_id = "external_dataset"
  
  external_tables = [
    {
      table_id      = "csv_data"
      source_format = "CSV"
      source_uris   = ["gs://my-bucket/data/*.csv"]
      autodetect    = true
      csv_options = {
        skip_leading_rows = 1
        field_delimiter   = ","
      }
    }
  ]
}
```

## Requirements

### Software Dependencies

- Terraform >= 0.13
- Google Cloud Provider >= 4.0

### GCP APIs

The following APIs must be enabled in your GCP project:

- BigQuery API (`bigquery.googleapis.com`)
- BigQuery JSON API (`bigquery-json.googleapis.com`)

### IAM Permissions

The service account or user running Terraform needs the following roles:

- `roles/bigquery.dataOwner` - For dataset and table management
- `roles/bigquery.admin` - For advanced features like routines and IAM management

## Best Practices

### Schema Management

1. **Use JSON Schema Files**: Store table schemas in separate JSON files for better maintainability
2. **Version Your Schemas**: Track schema changes in version control
3. **Test Schema Changes**: Validate schema changes in development environments first

### Partitioning Strategy

1. **Time Partitioning**: Use for time-series data to improve query performance and reduce costs
2. **Range Partitioning**: Use for evenly distributed integer columns
3. **Clustering**: Combine with partitioning for optimal performance

### Security

1. **Principle of Least Privilege**: Grant minimum necessary permissions
2. **Use IAM Conditions**: Implement time-based or attribute-based access controls
3. **Audit Access**: Regularly review dataset access permissions

### Cost Optimization

1. **Set Expiration Times**: Configure table and partition expiration to manage storage costs
2. **Use Appropriate Storage Classes**: Choose between logical and physical storage billing
3. **Monitor Query Costs**: Use clustering and partitioning to reduce query costs

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure the service account has necessary BigQuery permissions
2. **Schema Validation Errors**: Validate JSON schema format before applying
3. **Partition Filter Required**: Some queries may require partition filters for partitioned tables

### Debugging

Enable Terraform debug logging:

```bash
export TF_LOG=DEBUG
terraform apply
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This module is released under the Apache 2.0 License. See [LICENSE](LICENSE) for details.

## Support

For issues and questions:

1. Check the [troubleshooting section](#troubleshooting)
2. Review [Google Cloud BigQuery documentation](https://cloud.google.com/bigquery/docs)
3. Open an issue in this repository
