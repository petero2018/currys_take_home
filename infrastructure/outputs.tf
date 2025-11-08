output "synapse_workspace_name" {
  value       = azurerm_synapse_workspace.main.name
  description = "Provisioned Synapse workspace name."
}

output "synapse_workspace_id" {
  value       = azurerm_synapse_workspace.main.id
  description = "Synapse workspace resource ID."
}

output "synapse_workspace_dev_endpoint" {
  value       = azurerm_synapse_workspace.main.connectivity_endpoints["dev"]
  description = "Dev endpoint for Synapse Studio."
}

output "synapse_workspace_sql_endpoint" {
  value       = azurerm_synapse_workspace.main.connectivity_endpoints["sqlOnDemand"]
  description = "Serverless SQL endpoint."
}

output "synapse_sql_pool_name" {
  value       = try(azurerm_synapse_sql_pool.dw[0].name, null)
  description = "Dedicated SQL pool name (null when not created)."
}

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



output "tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Azure Active Directory tenant ID used by Terraform."
}

output "subscription_id" {
  value       = data.azurerm_client_config.current.subscription_id
  description = "Azure subscription ID targeted by Terraform."
}
