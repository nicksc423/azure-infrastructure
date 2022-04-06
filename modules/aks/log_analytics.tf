# -----------------------
# Log Analytics Workspace
# -----------------------
# This enables Azure's logging integration with the cluster.
resource "azurerm_log_analytics_workspace" "cluster" {
    name = var.cluster_name
    location = var.region
    resource_group_name = var.resource_group.name
    sku = "PerGB2018"
    retention_in_days = 30
}

resource "azurerm_log_analytics_solution" "cluster" {
    solution_name = "ContainerInsights"
    location = var.region
    resource_group_name = var.resource_group.name
    workspace_resource_id = azurerm_log_analytics_workspace.cluster.id
    workspace_name = azurerm_log_analytics_workspace.cluster.name
    plan {
        publisher = "Microsoft"
        product = "OMSGallery/ContainerInsights"
    }
}
