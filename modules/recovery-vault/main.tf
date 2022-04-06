# -----------------
# Disaster Recovery
# -----------------
# A number of resources create automatic backups and store them in an Azure recovery services vault. For example, the
# GitLab instance (including both configuration and data) are backed up and stored using this service. We create a
# generic top-level vault here to manage all of our backups in one location.
resource "azurerm_recovery_services_vault" "main" {
    name = "${var.resource_prefix}-backups"
    location = var.region
    resource_group_name = var.resource_group.name
    sku = "Standard"
}
