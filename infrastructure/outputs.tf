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
