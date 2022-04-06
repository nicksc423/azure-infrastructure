# --------------
# Notes
# --------------
# We store all the databases within the postgres server we make here


resource "azurerm_postgresql_database" "kong" {
    name = "kong"
    resource_group_name = var.resource_group.name
    server_name = azurerm_postgresql_server.db.name
    charset = "UTF8"
    collation = "en-US"
}

resource "azurerm_postgresql_database" "service-db" {
    name = "service-db"
    resource_group_name = var.resource_group.name
    server_name = azurerm_postgresql_server.db.name
    charset = "UTF8"
    collation = "en-US"
}
