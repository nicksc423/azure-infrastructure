# ----------------
# Managed Identity
# ----------------
# A managed identity is a service account that is associated with virtual machine instances, in this case the
# GitLab build runners. This allows us to grant permissions for build pipelines to access Azure resources like
# the Azure Container Registry. These permissions are granted elsewhere by each specific project.
resource "azurerm_user_assigned_identity" "gitlab" {
    name = var.identity_name
    location = var.region
    resource_group_name = var.resource_group.name
}

# Allow GitLab runners to push images.
resource "azurerm_role_assignment" "gitlab_acrpush" {
    principal_id = azurerm_user_assigned_identity.gitlab.principal_id
    scope = var.registry.id
    role_definition_name = "acrpush"
}

# Allow GitLab runners to pull images.
resource "azurerm_role_assignment" "gitlab_acrpull" {
    principal_id = azurerm_user_assigned_identity.gitlab.principal_id
    scope = var.registry.id
    role_definition_name = "acrpull"
}

# Allow the service account to publish metrics to Azure Monitor for the subscription.
resource "azurerm_role_assignment" "gitlab_metrics_pub" {
    principal_id = azurerm_user_assigned_identity.gitlab.principal_id
    scope = var.subscription_primary_id
    role_definition_name = "Monitoring Metrics Publisher"
}
