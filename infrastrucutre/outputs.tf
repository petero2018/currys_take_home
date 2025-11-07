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