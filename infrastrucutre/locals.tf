
locals {
  env_suffix               = replace(var.environment, "-", "")
  resource_group_name      = "rg-${var.project_name}-${var.environment}"
  storage_account_name_raw = "st${var.project_name}${local.env_suffix}"
  storage_account_name     = substr(lower(local.storage_account_name_raw), 0, 24)
  filesystem_name          = "${replace(var.project_name, "-", "")}${local.env_suffix}fs"
  synapse_workspace_name   = "syn-${var.project_name}-${var.environment}"
  synapse_sql_pool_name    = "sqlpool_${replace(var.project_name, "-", "_")}_${replace(var.environment, "-", "_")}"
}
