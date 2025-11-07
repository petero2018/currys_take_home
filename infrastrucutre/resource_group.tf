# resource_group.tf

resource "azurerm_resource_group" "data" {
  name     = local.resource_group_name
  location = var.location
}
