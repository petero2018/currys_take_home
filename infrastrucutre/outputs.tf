/*
output "synapse_workspace_name" {
  value       = azurerm_synapse_workspace.main.name
  description = "Provisioned Synapse workspace."
}

output "synapse_sql_pool_name" {
  value       = try(azurerm_synapse_sql_pool.dw[0].name, null)
  description = "Dedicated SQL pool name (null when not created)."
}
*/

output "storage_account_key" {
  value     = azurerm_storage_account.st.primary_access_key
  sensitive = true
}