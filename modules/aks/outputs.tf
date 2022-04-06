# --------------------
# Finish Cluster Setup
# --------------------
# This resource writes out a kubeconfig file with admin-level privileges (this is NOT checked into the repo). It then
# runs a setup script to complete the cluster's configuration.
#
# For details on what this script does, see common/cluster/cluster-setup.sh
#
# High-level overview:
# - Creates a binding to allow users in the cluster admin AD group to perform cluster-level operations.
# - Initializes helm, a Kubernetes app deployment tool.
# - Installs the cert-manager service for provisioning SSL certs.
# - Request a wildcard certificate for the top-level cluster domain.
# - Installs and configures nginx-ingress to use the SSL cert.
# - Creates default cluster-wide storage classes for apps that need persistent storage.
# - Installs Prometheus and Grafana dashboard connected to Azure Monitor with AD integration.
#
# A number of arguments are passed into the script in the form of environment variables sourced from the various
# resources defined in this file.
resource "local_file" "kubesetup" {
    filename = "./out/cluster/${var.cluster_name}/kubeconfig-admin"
    content = azurerm_kubernetes_cluster.cluster.kube_admin_config_raw
}

resource "local_file" "fluentbit_env" {
    filename = "./out/cluster/${var.cluster_name}/fluentbit.env"
    content = <<EOF
FLUENT_AZURE_WORKSPACE_ID = "${azurerm_log_analytics_workspace.cluster.workspace_id}"
FLUENT_AZURE_WORKSPACE_KEY = "${azurerm_log_analytics_workspace.cluster.secondary_shared_key}"
EOF
}

resource "local_file" "certmanager_env" {
    filename = "./out/cluster/${var.cluster_name}/certmanager.env"
    content = <<EOF
export AZURE_SUBSCRIPTION_ID="${data.azurerm_subscription.current.subscription_id}"
export AZURE_DNS_ZONE_RESOURCE_GROUP="${var.resource_group.name}"
export DNS_ZONE_NAME="${azurerm_dns_zone.cluster_zone.name}"
EOF
}

resource "local_file" "nginxingress_env" {
    filename = "./out/cluster/${var.cluster_name}/nginxingress.env"
    content = <<EOF
export INGRESS_IP="${azurerm_public_ip.ingress.ip_address}"
export AZURE_RESOURCE_GROUP="${var.resource_group.name}"
EOF
}
