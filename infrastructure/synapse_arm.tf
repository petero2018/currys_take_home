data "azurerm_client_config" "current" {}

locals {
  synapse_template_path = "${path.module}/synapse/template.json"
}

resource "random_uuid" "synapse_storage_role" {
  count = var.deploy_synapse_arm ? 1 : 0
}

resource "azurerm_resource_group_template_deployment" "synapse" {
  count               = var.deploy_synapse_arm ? 1 : 0
  name                = "synapse-arm-${var.environment}"
  resource_group_name = azurerm_resource_group.data.name
  deployment_mode     = "Incremental"

  template_content = file(local.synapse_template_path)

  parameters_content = jsonencode({
    name                                     = { value = local.synapse_workspace_name }
    location                                 = { value = var.location }
    defaultDataLakeStorageAccountName        = { value = azurerm_storage_account.datalake.name }
    defaultDataLakeStorageFilesystemName     = { value = azurerm_storage_data_lake_gen2_filesystem.default.name }
    sqlAdministratorLogin                    = { value = var.synapse_sql_admin_login }
    sqlAdministratorLoginPassword            = { value = var.synapse_sql_admin_password }
    setWorkspaceIdentityRbacOnStorageAccount = { value = true }
    createManagedPrivateEndpoint             = { value = false }
    defaultAdlsGen2AccountResourceId         = { value = azurerm_storage_account.datalake.id }
    azureADOnlyAuthentication                = { value = var.synapse_azure_ad_only_authentication }
    allowAllConnections                      = { value = var.synapse_allow_all_connections }
    managedVirtualNetwork                    = { value = "" }
    tagValues                                = { value = var.synapse_tags }
    storageSubscriptionID                    = { value = data.azurerm_client_config.current.subscription_id }
    storageResourceGroupName                 = { value = azurerm_resource_group.data.name }
    storageLocation                          = { value = var.location }
    storageRoleUniqueId                      = { value = random_uuid.synapse_storage_role[0].result }
    isNewStorageAccount                      = { value = false }
    isNewFileSystemOnly                      = { value = false }
    adlaResourceId                           = { value = "" }
    managedResourceGroupName                 = { value = "" }
    storageAccessTier                        = { value = "Hot" }
    storageAccountType                       = { value = "Standard_LRS" }
    storageSupportsHttpsTrafficOnly          = { value = true }
    storageKind                              = { value = "StorageV2" }
    minimumTlsVersion                        = { value = "TLS1_2" }
    storageIsHnsEnabled                      = { value = true }
    userObjectId                             = { value = var.synapse_user_object_id }
    setSbdcRbacOnStorageAccount              = { value = var.synapse_user_object_id != "" }
    setWorkspaceMsiByPassOnStorageAccount    = { value = false }
    workspaceStorageAccountProperties        = { value = {} }
  })
}

data "azurerm_synapse_workspace" "current" {
  count               = var.deploy_synapse_arm ? 1 : 0
  name                = local.synapse_workspace_name
  resource_group_name = azurerm_resource_group.data.name
  depends_on          = [azurerm_resource_group_template_deployment.synapse]
}
