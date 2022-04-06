# ---------------------------------
# Azure Kubernetes Service: Cluster
# ---------------------------------
# Here we create the actual cluster! This takes about 8-10 minutes in my experience.
resource "azurerm_kubernetes_cluster" "cluster" {
    name = var.cluster_name
    location = var.region
    resource_group_name = var.resource_group.name
    dns_prefix = var.cluster_name
    kubernetes_version = var.kubernetes_version

    api_server_authorized_ip_ranges = var.authorized_api_ips

    # Every VM node will be created with these settings. No service-level data will be stored on the nodes' disks, so we
    # use a minimal, non-configurable disk size. Every node gets connected to our existing subnet.
    default_node_pool {
        name = "default"
        vm_size = var.agent_size
        os_disk_size_gb = 128
        vnet_subnet_id = azurerm_subnet.subnet.id
        enable_auto_scaling = true
        min_count = var.cluster_min_nodes
        max_count = var.cluster_max_nodes
    }

    # RBAC/Azure AD integration section
    # Integrates an AD Group which members will have admin access to the AKS Cluster
    role_based_access_control {
      enabled = true
      azure_active_directory {
        managed = true
        admin_group_object_ids = [azuread_group.cluster_admins.object_id]
      }
    }

    identity {
      type = "UserAssigned"
      user_assigned_identity_id = azurerm_user_assigned_identity.identity.id
    }

    # We use the basic "kubenet" networking proider because we don't need to connect individual pods to our VNet. In
    # some circumstances, the advanced networking type may be desirable. See this page for a comparison:
    # https://docs.microsoft.com/en-us/azure/aks/concepts-network
    # We also enable the calico network plugin so we can use the Kubernetes NetworkPolicy resources.
    network_profile {
        network_plugin = "kubenet"
        load_balancer_sku = "Standard"
        network_policy = "calico"
    }

    # Node-level credentials for SSH.
    linux_profile {
        admin_username = var.node_admin_username
        ssh_key {
            key_data = file(var.node_admin_pubkey_file)
        }
    }

    # Special Azure integrations.
    addon_profile {
        # Dashboard is enabled by default; we don't need it and it's a notorious security hole.
        kube_dashboard {
            enabled = false
        }
    }

    # Need lifecycle ignore_changes on the addon_profile, because you can't delete it once added
    # without it causing you to reroll an entirely new cluster
    lifecycle {
      ignore_changes = [addon_profile]
    }
}
