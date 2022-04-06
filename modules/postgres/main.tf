resource "random_string" "admin_passwd" {
    length = 16
    special = true
}

resource "azurerm_postgresql_server" "db" {
    name = var.db_name
    location = var.region
    resource_group_name = var.resource_group.name
    sku_name = "GP_Gen5_2"

    storage_mb = 20480
    backup_retention_days = 7
    geo_redundant_backup_enabled = false
    auto_grow_enabled = true

    administrator_login = "postgres"
    administrator_login_password = random_string.admin_passwd.result
    version = "11"
    ssl_enforcement_enabled = true

    # Ignoring changes to password because terraform 0.12.29 cant import strings
    # Fix will be to import the existing password into the admin_passwd
    lifecycle {
      ignore_changes = [administrator_login_password]
    }
}

resource "azurerm_postgresql_firewall_rule" "allow_all" {
    name = "allow_all"
    resource_group_name = var.resource_group.name
    server_name = azurerm_postgresql_server.db.name
    start_ip_address = "0.0.0.0"
    end_ip_address = "255.255.255.255"
}

# A bit odd, but this is what switches the `Allow access to Azure services` switch to On
resource "azurerm_postgresql_firewall_rule" "allow_azure" {
    name = "allow_azure"
    resource_group_name = var.resource_group.name
    server_name = azurerm_postgresql_server.db.name
    start_ip_address = "0.0.0.0"
    end_ip_address = "0.0.0.0"
}
