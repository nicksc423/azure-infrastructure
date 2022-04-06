# Create AD group for cluster admins.
resource "azuread_group" "cluster_admins" {
    display_name = "${var.cluster_name}-admins"
}

# This role assignment allows users to use "az aks get-credentials ..."
resource "azurerm_role_assignment" "cluster_admins" {
    principal_id = azuread_group.cluster_admins.id
    scope = azurerm_kubernetes_cluster.cluster.id
    role_definition_name = "Azure Kubernetes Service Cluster User Role"
}

resource "azurerm_user_assigned_identity" "identity" {
  name                = "${var.cluster_name}-identity"
  resource_group_name = var.resource_group.name
  location            = var.region
}

# Apply the "Network Contributor" role to the cluster's service account. This is required because the cluster may need
# to modify network-related resources on the subnet. For example, it may need to provision a load balancer and connect
# it to the subnet.
resource "azurerm_role_assignment" "subnet_netcontrib" {
    principal_id = azurerm_user_assigned_identity.identity.principal_id
    scope = azurerm_subnet.subnet.id
    role_definition_name = "Network Contributor"
}

# Apply the same role, but scoped to the cluster's resource group. Other resources created in the group, such as public IPs
# may need to be modified or updated by the cluster.
resource "azurerm_role_assignment" "rg_netcontrib" {
    principal_id = azurerm_user_assigned_identity.identity.principal_id
    scope = var.resource_group.id
    role_definition_name = "Network Contributor"
}

resource "azurerm_role_assignment" "cluster_acrpull" {
    principal_id = azurerm_user_assigned_identity.identity.principal_id
    scope = var.registry.id
    role_definition_name = "acrpull"
}

# Grant DNS Zone Privileges to the Top Level domains
resource "azurerm_role_assignment" "cluster_dns_zone" {
    principal_id = azurerm_user_assigned_identity.identity.principal_id
    scope = azurerm_dns_zone.cluster_zone.id
    role_definition_name = "DNS Zone Contributor"
    skip_service_principal_aad_check = true # Allows skipping propagation of identity to ensure assignment succeeds.
}

resource "azurerm_role_assignment" "app_dns_zone" {
    for_each =  { for az in azurerm_dns_zone.app_zone : az.name => az }

    principal_id = azurerm_user_assigned_identity.identity.principal_id
    scope = each.value.id
    role_definition_name = "DNS Zone Contributor"
    skip_service_principal_aad_check = true # Allows skipping propagation of identity to ensure assignment succeeds.
}

# Apply the "Network Contributor" role to the kubelet service account. This is required because the kubelet may need
# to modify network-related resources on the subnet. For example, it may need to provision a load balancer and connect
# it to the subnet.
resource "azurerm_role_assignment" "kubelet_identity_subnet_netcontrib" {
    principal_id = azurerm_kubernetes_cluster.cluster.kubelet_identity[0].object_id
    skip_service_principal_aad_check = true # Allows skipping propagation of identity to ensure assignment succeeds.
    scope = azurerm_subnet.subnet.id
    role_definition_name = "Network Contributor"
}

# Apply the same role, but scoped to the cluster's resource group. Other resources created in the group, such as public IPs
# may need to be modified or updated by the cluster.
resource "azurerm_role_assignment" "kubelet_identity_rg_netcontrib" {
    principal_id = azurerm_kubernetes_cluster.cluster.kubelet_identity[0].object_id
    skip_service_principal_aad_check = true # Allows skipping propagation of identity to ensure assignment succeeds.
    scope = var.resource_group.id
    role_definition_name = "Network Contributor"
}

resource "azurerm_role_assignment" "kubelet_identity_cluster_acrpull" {
    principal_id = azurerm_kubernetes_cluster.cluster.kubelet_identity[0].object_id
    skip_service_principal_aad_check = true # Allows skipping propagation of identity to ensure assignment succeeds.
    scope = var.registry.id
    role_definition_name = "acrpull"
}

# Grant DNS Zone Privileges to the Top Level domains
resource "azurerm_role_assignment" "kubelet_identity_cluster_dns_zone" {
    principal_id = azurerm_kubernetes_cluster.cluster.kubelet_identity[0].object_id
    skip_service_principal_aad_check = true # Allows skipping propagation of identity to ensure assignment succeeds.
    scope = azurerm_dns_zone.cluster_zone.id
    role_definition_name = "DNS Zone Contributor"
}

resource "azurerm_role_assignment" "kubelet_identity_app_dns_zone" {
    for_each =  { for az in azurerm_dns_zone.app_zone : az.name => az }

    principal_id = azurerm_kubernetes_cluster.cluster.kubelet_identity[0].object_id
    skip_service_principal_aad_check = true # Allows skipping propagation of identity to ensure assignment succeeds.
    scope = each.value.id
    role_definition_name = "DNS Zone Contributor"
}
