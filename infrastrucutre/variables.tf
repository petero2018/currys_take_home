# variables.tf

variable "project_name" {
  type        = string
  description = "Lowercase project slug used to derive Azure resource names."
  default     = "currys"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,16}$", var.project_name))
    error_message = "project_name must be 3-16 characters and contain only lowercase letters, numbers, or hyphens."
  }
}

variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "uksouth"
}

variable "environment" {
  type        = string
  description = "Deployment environment label (e.g., dev, prod)."
  default     = "prod"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,10}$", var.environment))
    error_message = "environment must be 2-10 characters and contain only lowercase letters, numbers, or hyphens."
  }
}

variable "synapse_sql_admin_login" {
  type        = string
  description = "Administrator login for the Synapse workspace."
  default     = "synadmin"
}

variable "synapse_sql_admin_password" {
  type        = string
  description = "Administrator password for the Synapse workspace."
  sensitive   = true

  validation {
    condition     = length(var.synapse_sql_admin_password) >= 12
    error_message = "Synapse administrator password must be at least 12 characters."
  }
}

variable "create_synapse_sql_pool" {
  type        = bool
  description = "Whether to provision the dedicated Synapse SQL pool. Disable to avoid DWU charges."
  default     = false
}

variable "synapse_sql_pool_sku" {
  type        = string
  description = "SKU for the Synapse SQL pool (DW100c, DW200c, etc.)."
  default     = "DW100c"
}
