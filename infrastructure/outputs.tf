output "storage_account_name" {
  value       = azurerm_storage_account.datalake.name
  description = "ADLS Gen2 storage account name."
}

output "storage_primary_access_key" {
  value       = azurerm_storage_account.datalake.primary_access_key
  description = "ADLS Gen2 storage account primary access key."
  sensitive = true
}

output "storage_filesystem_name" {
  value       = azurerm_storage_data_lake_gen2_filesystem.default.name
  description = "Primary filesystem used by Synapse."
}

output "synapse_workspace_name" {
  value       = var.deploy_synapse_arm ? local.synapse_workspace_name : null
  description = "Synapse workspace name (null when not deployed)."
}

output "synapse_dev_endpoint" {
  value       = var.deploy_synapse_arm ? one(data.azurerm_synapse_workspace.current[*].connectivity_endpoints["dev"]) : null
  description = "Synapse Studio (dev) endpoint when deployed."
}

output "synapse_sql_endpoint" {
  value       = var.deploy_synapse_arm ? one(data.azurerm_synapse_workspace.current[*].connectivity_endpoints["sqlOnDemand"]) : null
  description = "Serverless SQL endpoint when deployed."
}

