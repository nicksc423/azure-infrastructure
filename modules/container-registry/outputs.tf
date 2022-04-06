# We mark sensitive to true because if we used Access Keys they would be visible in plain text
# See: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry
# Since we dont use Access Keys we actually have no sensitive values.
# You can view this in the state file
output "registry" {
    value = azurerm_container_registry.main
    sensitive = true
}
