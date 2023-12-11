variable "rg_name" {
  type = string
}

variable "location" {
  type = string
  default = "westus3"
}

# LOG ANALYTICS
variable "law_name" {
  type = string
  description = "Log Analytics Workspace name"
}

variable "law_sku" {
  type = string
  description = "Log Analytics Workspace SKU"
  default = "PerGB2018"
}

# APPLICATION INSIGHTS
variable "app_insights_name" {
  type = string
  description = "Application Insights name"
}

# NETWORKING
variable "vnet_name" {
  type = string
  description = "Virtual Network name"
}

variable "vnet_address_space" {
  type = list(string)
  description = "Virtual Network address space"
}

variable "snet_common_name" {  
  type = string
  description = "Subnet name"
}

variable "snet_common_cidr" {
  type = string
  description = "Subnet CIDR"
}

# private endpoint
variable "private_endpoint_name" {
  type = string
  description = "Private Endpoint name"
}

# Storage
variable "storage_account_name" {
  type = string
  description = "Storage Account name"
}

variable "storage_account_replication_type" {
  description = "(Optional) Specifies the replication type of the storage account"
  default     = "LRS"
  type        = string
}

variable "storage_account_kind" {
  description = "(Optional) Specifies the account kind of the storage account"
  default     = "StorageV2"
  type        = string
}

variable "ip_rules" {
  description = "IP rules for the storage account"
  type = list(string)
  default = []
}

variable "storage_account_tier" {
  description = "(Optional) Specifies the account tier of the storage account"
  default     = "Standard"
  type        = string
}

# Private DNS Zone
variable "private_dns_zone_name" {
  type = string
  description = "Private DNS Zone name"
}

# CONTAINER APP
variable "managed_environment_name" {
  type = string
  description = "Container App Managed Environment name" 
}

variable "container_app_image" {
  type = string
  description = "Image for the container app"
}

variable "container_app_name" {
  type = string
  description = "Container App name"
}