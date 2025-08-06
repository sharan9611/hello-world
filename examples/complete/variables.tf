# =============================================================================
# Variables for Complete BigQuery Module Example
# =============================================================================

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "The location for BigQuery dataset (US, EU, or specific region)"
  type        = string
  default     = "US"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "data_analyst_email" {
  description = "Email of the data analyst who needs access to the dataset"
  type        = string
  default     = null
}

variable "data_team_group_email" {
  description = "Email of the data team Google group"
  type        = string
  default     = null
}

variable "readonly_group_email" {
  description = "Email of the readonly access Google group"
  type        = string
  default     = null
}

variable "service_account_email" {
  description = "Email of the service account that needs access"
  type        = string
  default     = null
}

variable "conditional_user_email" {
  description = "Email of the user with conditional access"
  type        = string
  default     = null
}

variable "data_bucket" {
  description = "Cloud Storage bucket containing data files"
  type        = string
  default     = null
}

variable "logs_bucket" {
  description = "Cloud Storage bucket containing log files"
  type        = string
  default     = null
}