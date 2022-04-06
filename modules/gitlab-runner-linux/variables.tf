# --------------
# General Variables
# --------------

variable "region" {
    type = string
}

variable "resource_group" {
}

# --------------
# VM Variables
# --------------

variable "runner_name" {
    type = string
}

variable "runner_disk_size" {
    type = string
}

variable "vm_size" {
    type = string
}

# --------------
# Monitoring Variables
# --------------

variable "monitoring_email" {
    type = string
}

# --------------
# Identity Variables
# --------------

variable "identity_name" {
    type = string
}

# The Azure Container Registry in which we want Pull & Push privileges
variable "registry" {
}

variable "subscription_primary_id" {
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

variable "staff_ips" {
    type = list(string)
}
