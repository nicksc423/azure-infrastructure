# Azure region the VNET will be hosted in
variable "region" {
    type = string
}

# The resource_group the VNET will be housed in
variable "resource_group" {
}

# We manually set the resource_name because Names are UUIDs in Azure
variable "resource_name" {
    type = string
}
