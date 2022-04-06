# Creates a subnet for GitLab resources.
resource "azurerm_subnet" "subnet" {
    resource_group_name = var.resource_group.name
    virtual_network_name = var.vnet.name
    name = "${var.vnet.name}-gitlab-subnet"
    address_prefixes = [var.subnet_cidr]
}

# Restrict the source IPs that can access the GitLab subnet. This is just an additional layer of security that is
# combined with authentication.
resource "azurerm_network_security_group" "nsg" {
    name = "${var.vnet.name}-gitlab-restricted"
    location = var.region
    resource_group_name = var.resource_group.name

    # Allow staff_ips to access any port
    security_rule {
        name = "staff"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "*"
        source_port_range = "*"
        destination_port_range = "*"
        source_address_prefixes = var.staff_ips
        destination_address_prefix = "*"
    }

    # Allow Port 80, Gitlab will automatically redirect to 443
    security_rule {
        name = "public-http"
        priority = 200
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    # To allow access over https
    security_rule {
        name = "public-https"
        priority = 201
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "443"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
}

# Associates the above network security group with this subnet.
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
    subnet_id = azurerm_subnet.subnet.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}
