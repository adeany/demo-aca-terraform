rg_name = "TEST3-amd-aca-tf"
location = "westus3"

# Log Analytics Workspace
law_name = "law-amd-test3-tf"
law_sku = "PerGB2018"

# App Insights
app_insights_name = "appinsights-amd-test3-tf"

# NETWORKING
vnet_name = "amd-test3-tf-vnet"
vnet_address_space = [ "10.0.0.0/16" ] 
snet_common_name = "snet3-common"
snet_common_cidr = "10.0.0.0/23"

# Private DNS Zone
private_dns_zone_name = "privatelink.azurecr.io"

# Private Endpoint
private_endpoint_name = "AMDTestACAPrivateEndpoint3"

# Storage
storage_account_name = "amdtest3acatfsa"
storage_account_kind = "StorageV2"
storage_account_replication_type = "LRS" 
storage_account_tier = "Standard"
ip_rules = ["100.0.0.1"]

# CONTAINER APP
managed_environment_name = "aca-env-amd-test3-tf"
container_app_name = "aca-amd-test3-tf"
container_app_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"