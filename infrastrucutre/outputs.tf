# outputs.tf

output "synapse_workspace_name" {
  value       = azurerm_synapse_workspace.main.name
  description = "Provisioned Synapse workspace."
}

output "synapse_sql_pool_name" {
  value       = azurerm_synapse_sql_pool.dw.name
  description = "Dedicated SQL pool name."
}
