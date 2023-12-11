rg_name = "TEST-amd-aca-tf"
location = "westus3"

# Log Analytics Workspace
law_name = "law-amd-test-tf"
law_sku = "PerGB2018"

# App Insights
app_insights_name = "appinsights-amd-test-tf"

# NETWORKING
vnet_name = "amd-test-tf-vnet"
vnet_address_space = [ "10.0.0.0/16" ]
snet_common_name = "snet-common"
snet_common_cidr = "10.0.0.0/23"

# Private DNS Zone
private_dns_zone_name = "privatelink.blob.core.windows.net"

# Private Endpoint
private_endpoint_name = "AMDTestACAPrivateEndpoint"

# Storage
storage_account_name = "amdtestacatfsa"
storage_account_kind = "StorageV2"
storage_account_replication_type = "LRS" 
storage_account_tier = "Standard"
ip_rules = ["100.0.0.1"]

# CONTAINER APP
managed_environment_name = "aca-env-amd-test-tf"
container_app_name = "aca-amd-test-tf"
container_app_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"