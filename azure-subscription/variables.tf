# ---------------
# Input Variables
# ---------------
# These are the different variables needed to make an environment.
# Their values are set in the terraform.tfvars file or are defaulted here if unlikely to change

# This is defaulted to our tenant_id, our tenant_id will never change unless we make a new Azure account
variable "tenant_id" {
    type = string
    default = ""
}

# This is the ID of the subscription we make.  The subscription is made manually prior to running terraform
variable "subscription_id" {
    type = string
    default = ""
}

# This is the region that all resources are made in
variable "region" {
    type = string
}

# A prefix for naming resources. Several Azure resources require globally-unique names (Azure Container Registry, for
# example). Adding the prefix ensures uniqueness and also potentially helps distinguish our own resources from each other
variable "resource_prefix" {
    type = string
}

# Many resources are locked down using Azure's network security groups. For example, SSH to various instances and access
# to Kubernetes API endpoint (via kubectl, etc.). Anything that should only be accessed by staff and not the public. The
# list can be expanded if other offices need access.
variable "staff_ips" {
    type = list(string)
}

# This domain is registered via Route53 but delegated to Azure's nameservers. This deployment creates sub-domains and
# DNS entries under this domain.
variable "dns_root_name" {
    type = string
}
