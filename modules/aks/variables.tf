# --------------
# General Variables
# --------------

# region AKS will be deployed to
variable "region" {
    type = string
}

# resource group object, we use to get name & ID
variable "resource_group" {
}

# List of Azure Container Registries in which we want Pull & Push privileges
variable "registry" {
}

# This data resource exposes certain values related to the current Azure subscription, such as the tenant ID and
# subscription ID. These values are required for some of the resources below.
data "azurerm_subscription" "current" {}

# --------------
# AKS Variables
# --------------

# Many resource names are prefixed with this value for better organization.
variable "cluster_name" {
    type = string
}

# The Kubernetes version to use. To list available versions for a particular region on Azure, run:
# az aks get-versions -l <region> --output table
variable "kubernetes_version" {
    type = string
}

# Number and type of VM agents (Kubernetes nodes) to create. These three settings are the main factors that directly
# impact the cost of a cluster.
# Min number of nodes that the cluster can have
variable "cluster_min_nodes" {
    type = number
}

# Max number of nodes that the cluster can have
variable "cluster_max_nodes" {
    type = number
}

# The "size" of the node/server
variable "agent_size" {
    type = string
}

# Admin SSH username on cluster nodes.
variable "node_admin_username" {
    type = string
}

# Admin public key to allow SSH on cluster nodes.
variable "node_admin_pubkey_file" {
    type = string
}

# --------------
# Networking Variables
# --------------

variable "vnet" {
}

variable "subnet_cidr" {
    type = string
}

# The IPs authorized to access the API (in addition to required built-in Azure services). Being on this list is required
# for running commands like kubectl, but it is NOT required for simply accessing services deployed to the cluster
# (ingress). This should be locked down as much as possible, and include only staff locations.
#
# Due to the design of Azure Kubernetes Service, this API endpoint does not live in our subnet and is thus not subject to
# the applied network security group. However, they do allow us to provide a list of IPs to white-list.
variable "authorized_api_ips" {
    type = list(string)
}

# List of IPs that are allowed to access resources in the cluster's subnet and agent nodes should be staff only).
variable "staff_ips" {
    type = list(string)
}

# --------------
# DNS Variables
# --------------

# Root Level DNS (company.net)
variable "dns_root_zone" {
}

# Root Level DNS's resource_group
variable "dns_root_rg" {
}

# All the services exposed from the cluster will live under this domain unless another domain is specifically
# provisioned for a service.
variable "dns_zone_name" {
    type = string
}

# Additional sub-domains (sub-zones of the dns_zone_name) setting above to provision. See the DNS section below for
# details.
variable "dns_app_zone_names" {
    type = list(string)
}
