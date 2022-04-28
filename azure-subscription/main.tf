# ---------------
# Storage Backend
# ---------------
# Instead of storing the .tfstate files here in the repo, we use a remote storage backend with encryption. The state
# file can contain secrets, such as service principal passwords, that we do not want committed to the repo.
#
# The storage account and container are created manually prior to terraform initialization.
terraform {
    backend "azurerm" {
        resource_group_name = "ops"
        storage_account_name = "ops"
        container_name = "ops-tf"
        key = "main.tfstate"
    }
}

# ---------------
# Azure Providers
# ---------------
# Terraform provides two separate plugins for Azure. One for managing Active Directory resources and one for all the
# cloud-based resources. We can use these two providers together to feed values to each other. For example, when
# creating an application or service account in AD, the resulting ID of those resources can be provided directly to
# cloud-based resources like VMs or clusters.
#
# This combination allows us to manage permissions using AD. An example of this is how we grant Push permissions on the
# Azure Container Registries to the GitLab service account so that builds can upload Docker images without the need to
# hard-code a password.
#
# To avoid any nasty surprises, we specify exact versions for each of these providers.
provider "azurerm" {
    subscription_id = var.subscription_id
    tenant_id = var.tenant_id
    features {}
}

provider "azuread" {
    tenant_id = var.tenant_id
}

provider "local" {
}

provider "random" {
}

# This is a representation of our current subscription
data "azurerm_subscription" "azure-subscription" {
}

#####################################
# GENERAL RESOURCES
#####################################

# ---------------
# Resource Groups
# ---------------
# Cloud resources belong to resource groups which provides a way to organize resources for billing and management
# purposes. We create resource groups to assist with billing and organization

# This RG is for resources that are shared across multiple projects.  The GitLab Master is a good example
resource "azurerm_resource_group" "general" {
    name = "${var.resource_prefix}-general"
    location = var.region
}

# -----------------
# Module: Recovery Vault
# -----------------
# A number of resources create automatic backups and store them in an Azure recovery services vault. For example, the
# GitLab instance (including both configuration and data) are backed up and stored using this service. We create a
# generic top-level vault here to manage all of our backups in one location.
module "recovery-vault" {
    source = "../modules/recovery-vault"

    resource_prefix = "${var.resource_prefix}"
    region = var.region
    resource_group = azurerm_resource_group.general
}

# ------------------
# Module: Container Registries
# ------------------
# Here we provision our various container registries.
module "registry" {
    source = "../modules/container-registry"

    registry_name = "${var.resource_prefix}registry"
    region = var.region
    resource_group = azurerm_resource_group.general
}

# --------------
# Module: DNS
# --------------
# We provision our Root Level DNS resources here.  They are utilized by the other environments and their terraform scripts.
module "dns" {
    source = "../modules/dns"

    dns_root_name = var.dns_root_name
    resource_group = azurerm_resource_group.general
}

#####################################
# END GENERAL RESOURCES
#####################################

#####################################
# ENV RESOURCES
#####################################

# ---------------
# Resource Groups
# ---------------
# Cloud resources belong to resource groups which provides a way to organize resources for billing and management
# purposes. Everything in the subscription will be put under one resource group
resource "azurerm_resource_group" "dev" {
    name = "${var.resource_prefix}-dev"
    location = var.region
}

# --------------
# Module: VNET
# --------------
# We make a VNET for dev to store our AKS cluster and a Gitlab runner to deploy to it

module "vnet" {
  source = "../modules/vnet"
  region = var.region
  resource_group = azurerm_resource_group.dev
  resource_name = "${var.resource_prefix}-dev"
}

# --------------
# Module: Postgres
# --------------
# Create a Postgres Server + Databases

module "postgres" {
    source = "../modules/postgres"

    db_name = "${var.resource_prefix}-dev"
    region = var.region
    resource_group = azurerm_resource_group.dev
}

# --------------------------
# Module: Azure Kubernetes Cluster
# --------------------------
# Here we make the AKS cluster.  The are much more in-depth comments in the module
# This is a very complicated module that creates a lot of infra (DNS, Networking, Identity, AKS, etc)
module "aks" {
    source = "../modules/aks"

    region = var.region
    resource_group = azurerm_resource_group.dev
    registry = module.registry.registry

    cluster_name = "${var.resource_prefix}-dev"
    kubernetes_version = "1.21.2"
    cluster_min_nodes = 3
    cluster_max_nodes = 3
    agent_size = "Standard_B4ms"
    node_admin_username = "admin"
    node_admin_pubkey_file = "admin_key.pub"

    vnet = module.vnet.vnet
    subnet_cidr = "172.16.2.0/24"

    authorized_api_ips = concat(var.staff_ips)
    staff_ips = var.staff_ips

    dns_root_zone = module.dns.root_zone
    dns_root_rg = azurerm_resource_group.general
    dns_zone_name = "dev"
    dns_app_zone_names = ["app"]
}

#####################################
# END ENV RESOURCES
#####################################
