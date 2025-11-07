# storage.tf

resource "azurerm_storage_account" "datalake" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.data.name
  location                 = azurerm_resource_group.data.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "default" {
  name               = local.filesystem_name
  storage_account_id = azurerm_storage_account.datalake.id
}
