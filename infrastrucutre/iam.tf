data "azurerm_client_config" "current" {}

locals {
  storage_blob_data_contributor_role_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
}

resource "azurerm_role_assignment" "workspace_storage_access" {
  scope              = azurerm_storage_account.datalake.id
  role_definition_id = local.storage_blob_data_contributor_role_id
  principal_id       = azurerm_synapse_workspace.main.identity[0].principal_id
  principal_type     = "ServicePrincipal"

  depends_on = [azurerm_synapse_workspace.main]
}

resource "azurerm_role_assignment" "extra_storage_access" {
  for_each          = { for principal in var.storage_blob_data_contributor_principals : principal.id => principal }
  scope             = azurerm_storage_account.datalake.id
  role_definition_id = local.storage_blob_data_contributor_role_id
  principal_id      = each.value.id
  principal_type    = each.value.type
}
