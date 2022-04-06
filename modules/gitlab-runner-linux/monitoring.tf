# --------------
# NOTES
# --------------
# This seems to break terraform a bit.
# Can't create the diskUsage alert until the VM reports it.
# TODO: see if its possible to create a delay

resource "azurerm_monitor_action_group" "main" {
  name                = "emailOpsAlerts"
  resource_group_name = var.resource_group.name
  short_name          = "emailAlerts"

  email_receiver {
    name                    = "sendtodevops"
    email_address           = var.monitoring_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "diskUsage" {
  name                = "gitlab-runner-disk-usage-alert"
  resource_group_name = var.resource_group.name
  scopes              = [azurerm_virtual_machine.runner.id]
  window_size         = "PT1H"
  frequency           = "PT30M"

  criteria {
    metric_namespace = "telegraf/disk"
    metric_name      = "used_percent"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
