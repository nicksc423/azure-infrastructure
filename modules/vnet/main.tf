# ---------------
# Virtual Network
# ---------------
# A VNet allows for internal communication between resources without traversing the public Internet. The VNet is split
# into subnets, one for each subject area. See below for the different subnets that are defined as part of this
# deployment.
#
# A VNet is required for any resource with a network interface. Virtual machines and load balancers are the two most
# common examples. The Kubernetes cluster nodes also live here.

resource "azurerm_virtual_network" "main" {
    name = var.resource_name
    location = var.region
    resource_group_name = var.resource_group.name
    address_space = ["172.16.0.0/16"]
}
