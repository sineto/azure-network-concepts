terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.19.1"
    }
  }

  required_version = "~> 1.2.7"
}

provider "azurerm" {
  features {}
}
