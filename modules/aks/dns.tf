# ----------------------------------------
# Azure DNS: Cluster and Application Zones
# ----------------------------------------
# To access any services hosted by the cluster, we need domain names for those services.
#
# We are using a wildcard DNS strategy to allow services to use their own hostnames. This makes it easier to deal with
# paths, since we no longer need to route requests based on request path and may simply use hostnames. Importantly,
# every DNS name provisioned is associated with a single IP address assigned to the ingress load balancer.

# Top level cluster zone (e.g., dev.company.net)
resource "azurerm_dns_zone" "cluster_zone" {
    name = "${var.dns_zone_name}.${var.dns_root_zone.name}"
    resource_group_name = var.resource_group.name
}

# Top zone delegation.
resource "azurerm_dns_ns_record" "root_zone_delegation" {
    name = var.dns_zone_name
    zone_name = var.dns_root_zone.name
    resource_group_name = var.dns_root_rg.name
    ttl = 300
    records = azurerm_dns_zone.cluster_zone.name_servers
}

# This record ensures that the domain itself (e.g., dev.company.net) resolves to the public IP.
resource "azurerm_dns_a_record" "root" {
    name = "@"
    zone_name = azurerm_dns_zone.cluster_zone.name
    resource_group_name = var.resource_group.name
    ttl = 300
    records = [azurerm_public_ip.ingress.ip_address]
}

# This record ensures that all hostnames in the domain (e.g., myservice.dev.company.net) resolves to the public IP.
resource "azurerm_dns_a_record" "wildcard" {
    name = "*"
    zone_name = azurerm_dns_zone.cluster_zone.name
    resource_group_name = var.resource_group.name
    ttl = 300
    records = [azurerm_public_ip.ingress.ip_address]
}

# This is a terraform "count" resource which means that zero, one or more identical resources are provisioned, one for
# each entry in the dns_app_zone_names list. This creates a sub-zone for every app or project.
# TODO: Maybe redo this with foreach function
resource "azurerm_dns_zone" "app_zone" {
    count = length(var.dns_app_zone_names)
    name = "${var.dns_app_zone_names[count.index]}.${var.dns_zone_name}.${var.dns_root_zone.name}"
    resource_group_name = var.resource_group.name
}

# For each sub-zone, delegate lookups to that zone using an NS entry in the top zone.
# TODO: Maybe redo this with new foreach function
resource "azurerm_dns_ns_record" "app_zone_delegation" {
    count = length(var.dns_app_zone_names)
    name = var.dns_app_zone_names[count.index]
    zone_name = "${var.dns_zone_name}.${var.dns_root_zone.name}"
    resource_group_name = var.resource_group.name
    ttl = 300
    records = azurerm_dns_zone.app_zone[count.index].name_servers
}

# Make lookups of the zone name resolve to the public IP (e.g., myproject.dev.company.net).
resource "azurerm_dns_a_record" "app_root" {
    count = length(var.dns_app_zone_names)
    name = "@"
    zone_name = azurerm_dns_zone.app_zone[count.index].name
    resource_group_name = var.resource_group.name
    ttl = 300
    records = [azurerm_public_ip.ingress.ip_address]
}

# Make lookups of any host in the sub-zone resolve to the public IP (e.g., myservice.myproject.dev.company.net).
resource "azurerm_dns_a_record" "app_wildcard" {
    count = length(var.dns_app_zone_names)
    name = "*"
    zone_name = azurerm_dns_zone.app_zone[count.index].name
    resource_group_name = var.resource_group.name
    ttl = 300
    records = [azurerm_public_ip.ingress.ip_address]
}
