# providers.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
  required_version = ">= 1.6.0"
}

provider "azurerm" {
  features {}
}
