# -------------
# Top-Level DNS
# -------------
# Here we create two top-level zones, one for public and one for private name resolution. This is referred to as a
# "split horizon" DNS strategy. When resolving hostnames, resources inside the Azure VNet will receive internal IP
# addresses for direct communication. Outside users will receive the published IP addresses which are subject to network
# security group requirements.
#
# A concrete example of this in action: when a GitLab build runner instance wants to communicate with the main GitLab
# server, it receives the internal IP address from the private zone; but when an external user accesses the web
# interface they receive the external IP address from the public zone.
resource "azurerm_dns_zone" "main" {
    name = var.dns_root_name
    resource_group_name = var.resource_group.name
}

resource "azurerm_private_dns_zone" "main" {
    name = var.dns_root_name
    resource_group_name = var.resource_group.name
}
