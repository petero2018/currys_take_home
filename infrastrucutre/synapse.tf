resource "azurerm_synapse_workspace" "main" {
  name                                 = local.synapse_workspace_name
  resource_group_name                  = azurerm_resource_group.data.name
  location                             = azurerm_resource_group.data.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.default.id
  sql_administrator_login              = var.synapse_sql_admin_login
  sql_administrator_login_password     = var.synapse_sql_admin_password

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_synapse_sql_pool" "dw" {
  count                = var.create_synapse_sql_pool ? 1 : 0
  name                 = local.synapse_sql_pool_name
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  sku_name             = var.synapse_sql_pool_sku
}
