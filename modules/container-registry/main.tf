# ------------------
# Container Registry
# ------------------
# This is a docker image registry that stores build artifacts, using Azure's Container Registry service. In most cases,
# the producer of images will be a GitLab runner (push & pull) and the consumer would be the Kubernetes cluster (pull).
resource "azurerm_container_registry" "main" {
    name = var.registry_name
    location = var.region
    resource_group_name = var.resource_group.name
    sku = "Standard"
    admin_enabled = false
}
