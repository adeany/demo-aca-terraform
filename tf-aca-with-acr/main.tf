terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.71.0"
    }
  }
}

provider "azurerm" {
  features {}
  # Configuration options
}

resource "random_id" "container_name" {
  byte_length = 4
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# LOG ANALYTICS WORKSPACE
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.law_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.law_sku
  retention_in_days   = 30
}

# APPLICATION INSIGHTS
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights
resource "azurerm_application_insights" "resource" {
  name                = var.app_insights_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
}

# NETWORKING
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "subnet" {
  name                                           = var.snet_common_name
  resource_group_name                            = azurerm_resource_group.rg.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = [var.snet_common_cidr]
  private_endpoint_network_policies_enabled     = false
  private_link_service_network_policies_enabled = false
  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry"
  ]
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting
resource "azurerm_monitor_diagnostic_setting" "settings" {
  name                       = "DiagnosticsSettings"
  target_resource_id         = azurerm_virtual_network.vnet.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
  }
}

# PRIVATE ENDPOINT
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint
resource "azurerm_private_endpoint" "private_endpoint" {
  name                = var.private_endpoint_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "${var.private_endpoint_name}Connection"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }
}

# PRIVATE DNS ZONE
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.rg.name
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link
resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  name                  = "link_to_${var.vnet_name}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

locals {
  acr_login_server = [
    for c in azurerm_private_endpoint.private_endpoint.custom_dns_configs : c.ip_addresses[0]
    if c.fqdn == "${azurerm_container_registry.acr.name}.azurecr.io"
  ][0]
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record
resource "azurerm_private_dns_a_record" "private" {
  name                = azurerm_container_registry.acr.name
  records             = [local.acr_login_server]
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
}

locals {
  data_endpoint_ips = { for e in azurerm_private_endpoint.private_endpoint.custom_dns_configs : e.fqdn => e.ip_addresses[0] }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record
resource "azurerm_private_dns_a_record" "data" {
  name = "${azurerm_container_registry.acr.name}.${var.location}.data"
  records = [
    local.data_endpoint_ips["${azurerm_container_registry.acr.name}.${var.location}.data.azurecr.io"]
  ]
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
}

# Fetch local IP address for network rules
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry
resource "azurerm_container_registry" "acr" {
  location                      = azurerm_resource_group.rg.location
  name                          = "acr${random_id.container_name.hex}"
  resource_group_name           = azurerm_resource_group.rg.name
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = true

  network_rule_set {
    default_action = "Deny"

    ip_rule {
      action   = "Allow"
      ip_range = chomp(data.http.myip.response_body)
    }
    virtual_network {
      action    = "Allow"
      subnet_id = azurerm_subnet.subnet.id
    }
  }
  retention_policy {
    days    = 7
    enabled = true
  }
  trust_policy {
    enabled = true
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/container_registry_scope_map
data "azurerm_container_registry_scope_map" "push_repos" {
  container_registry_name = azurerm_container_registry.acr.name
  name                    = "_repositories_push"
  resource_group_name     = azurerm_container_registry.acr.resource_group_name
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/container_registry_scope_map
data "azurerm_container_registry_scope_map" "pull_repos" {
  container_registry_name = azurerm_container_registry.acr.name
  name                    = "_repositories_pull"
  resource_group_name     = azurerm_container_registry.acr.resource_group_name
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry_token
resource "azurerm_container_registry_token" "pushtoken" {
  container_registry_name = azurerm_container_registry.acr.name
  name                    = "pushtoken"
  resource_group_name     = azurerm_container_registry.acr.resource_group_name
  scope_map_id            = data.azurerm_container_registry_scope_map.push_repos.id
}

resource "azurerm_container_registry_token" "pulltoken" {
  container_registry_name = azurerm_container_registry.acr.name
  name                    = "pulltoken"
  resource_group_name     = azurerm_container_registry.acr.resource_group_name
  scope_map_id            = data.azurerm_container_registry_scope_map.pull_repos.id
}

resource "azurerm_container_registry_token_password" "pushtokenpassword" {
  container_registry_token_id = azurerm_container_registry_token.pushtoken.id

  password1 {
    expiry = timeadd(timestamp(), "24h")
  }
  lifecycle {
    ignore_changes = [password1]
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry_token_password
resource "azurerm_container_registry_token_password" "pulltokenpassword" {
  container_registry_token_id = azurerm_container_registry_token.pulltoken.id

  password1 {
    expiry = timeadd(timestamp(), "24h")
  }
  lifecycle {
    ignore_changes = [password1]
  }
}

# CONTAINER APP
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment
resource "azurerm_container_app_environment" "managed_environment" {
  name                           = var.managed_environment_name
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.id
  infrastructure_subnet_id       = azurerm_subnet.subnet.id
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app
resource "azurerm_container_app" "container_app" {
  name                         = var.container_app_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.managed_environment.id
  revision_mode                = "Single"

  template {
    container {
      name   = var.container_app_name
      image  = var.container_app_image
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
      external_enabled           = true
      target_port                = 80
      allow_insecure_connections = false
      traffic_weight {
        percentage               = 100
      }
  }
}