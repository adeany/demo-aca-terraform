variable "rg_name" {
  type = string
}

variable "location" {
  type = string
  default = "westus3"
}

# CONTAINER APP
variable "container_app_name" {
  type = string
  description = "Container App name"
}