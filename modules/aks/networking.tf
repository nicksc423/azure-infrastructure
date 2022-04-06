# Creates a subnet for all AKS resources.
resource "azurerm_subnet" "subnet" {
    resource_group_name = var.resource_group.name
    virtual_network_name = var.vnet.name
    name = "${var.vnet.name}-cluster"
    address_prefixes = [var.subnet_cidr]
}

# ---------------
# Service Ingress
# ---------------
# These resources allow users outside the cluster to access services and apps that have been published to the cluster.
# A single IP address is assigned to the load balancer, and services are distinguished by their hostnames (see DNS below)
# and paths. The IP address here is associated with an Azure load balancer automatically by the nginx-ingress controller
# hosted inside the cluster.

resource "azurerm_public_ip" "ingress" {
    name = "${var.cluster_name}-ingress"
    location = var.region
    resource_group_name = var.resource_group.name
    allocation_method = "Static"
    sku = "Standard"

    tags = {
      service = "nginx-ingress/main-ingress-nginx-ingress-controller"
    }
}

# See input variables for the parameter that defines how access to services/apps is restricted
# (if at all). This security group allows inbound web connects to port 80 and port 443. Other built-in rules are
# automatically appended to the group to allow Azure resources to connect to the cluster as needed.
resource "azurerm_network_security_group" "ingress" {
    name = "${var.cluster_name}-ingress"
    location = var.region
    resource_group_name = var.resource_group.name

    # HTTPS connections. Note that the desintation IP here is the public ingress IP. We do not allow HTTPS connections
    # to any other resource. Generally this would be available to the public.
    security_rule {
        name = "public-https"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "443"
        source_address_prefix = "*"
        destination_address_prefix = azurerm_public_ip.ingress.ip_address
    }
    # To allow letsnecrypt to operate, we must leave port 80 open to everyone. Deployed services should never run
    # on port 80, but should instead run on port 443 with HTTPS. See the helm chart examples for the annotations required to use HTTPS.
    security_rule {
        name = "public-http"
        priority = 200
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "*"
        destination_address_prefix = azurerm_public_ip.ingress.ip_address
    }
    # Allow staff locations to access anything, including SSH into the cluster nodes.
    security_rule {
        name = "staff"
        priority = 300
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "*"
        source_address_prefixes = var.staff_ips
        destination_address_prefix = "*"
    }
}

# Associate the security group with the cluster's subnet.
resource "azurerm_subnet_network_security_group_association" "cluster" {
    subnet_id = azurerm_subnet.subnet.id
    network_security_group_id = azurerm_network_security_group.ingress.id
}
