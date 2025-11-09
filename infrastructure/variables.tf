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
