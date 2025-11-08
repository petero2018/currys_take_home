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
  default     = "northeurope"
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

variable "storage_blob_data_contributor_principals" {
  description = "Principals (users/SPs/groups) to grant Storage Blob Data Contributor on the ADLS account."
  type = list(object({
    id   = string
    type = string
  }))
  default = []
}

variable "deploy_synapse_arm" {
  description = "Whether to deploy the Synapse workspace via the provided ARM template."
  type        = bool
  default     = false
}

variable "synapse_sql_admin_login" {
  type        = string
  description = "Administrator login for the Synapse workspace (used by dbt or SQL clients)."
  default     = "synadmin"
}

variable "synapse_sql_admin_password" {
  type        = string
  description = "Administrator password for the Synapse workspace."
  sensitive   = true
}

variable "synapse_user_object_id" {
  type        = string
  description = "Azure AD object ID to grant Synapse Administrator and storage access (your user or group)."
  default     = ""
}

variable "synapse_allow_all_connections" {
  type        = bool
  description = "Allow public endpoints (0.0.0.0) for Synapse firewall."
  default     = true
}

variable "synapse_azure_ad_only_authentication" {
  type        = bool
  description = "Enforce Azure AD only authentication for Synapse."
  default     = true
}

variable "synapse_tags" {
  type        = map(any)
  description = "Optional tags to apply to the Synapse workspace via the ARM template."
  default     = {}
}
