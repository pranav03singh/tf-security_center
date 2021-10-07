#----------------------------------------------------------
# Generate Random Integer
#----------------------------------------------------------
resource "random_integer" "random_value" {
  min = 100
  max = 50000
}


#----------------------------------------------------------
# Resource Group, Log Analytics Data Resources
#----------------------------------------------------------
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_log_analytics_workspace" "logws" {
  name                = var.log_analytics_workspace_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

#----------------------------------------------------------
# Current Subscription Data Resources
#----------------------------------------------------------

data "azurerm_subscription" "current" {}

#---------------------------------------------------------
# Resource Group Creation or selection - Default is "false"
#----------------------------------------------------------

data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.resource_group_location
  tags     = merge({ "Name" = format("%s", var.resource_group_name) }, var.tags, )
}


#----------------------------------------------------------
# Log Analytics Workspace Resource
#----------------------------------------------------------
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.log_analytics_workspace_name ? 0 : 1
  name                = "log-ws-"+random_integer.random_value
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

#----------------------------------------------------------
# Azure Security Center Workspace Resource
#----------------------------------------------------------

resource "azurerm_security_center_workspace" "main" {
  scope        = var.scope_resource_id == null ? data.azurerm_subscription.current.id : var.scope_resource_id
  workspace_id = azurerm_log_analytics_workspace.main.id
}

#----------------------------------------------------------
# Azure Security Center Subscription Pricing Resources
#----------------------------------------------------------

resource "azurerm_security_center_subscription_pricing" "main" {
  tier          = var.security_center_subscription_pricing
  resource_type = var.resource_type
}

#----------------------------------------------------------
# Azure Security Center Contact Resources
#----------------------------------------------------------
resource "azurerm_security_center_contact" "main" {
  email               = lookup(var.security_center_contacts, "email")
  phone               = lookup(var.security_center_contacts, "phone", null)
  alert_notifications = lookup(var.security_center_contacts, "alert_notifications", true)
  alerts_to_admins    = lookup(var.security_center_contacts, "alerts_to_admins", true)
}

resource "azurerm_security_center_setting" "main" {
  count        = var.enable_security_center_setting ? 1 : 0
  setting_name = var.security_center_setting_name
  enabled      = var.enable_security_center_setting
}

resource "azurerm_security_center_auto_provisioning" "main" {
  count          = var.enable_security_center_auto_provisioning == "On" ? 1 : 0
  auto_provision = var.enable_security_center_auto_provisioning
}
