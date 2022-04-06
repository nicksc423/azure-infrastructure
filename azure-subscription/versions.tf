terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "1.4.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.56.0"
    }
    local = {
      source = "hashicorp/local"
      version = "2.1.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }
  required_version = ">= 0.15"
}
