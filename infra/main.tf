provider "azurerm" {
  features {}
}

variable "apiManagementServiceName" {
  description = "The name of the API Management service instance"
  type        = string
  default     = "apiservice${random_string.suffix.result}"
}

variable "publisherEmail" {
  description = "The email address of the owner of the service"
  type        = string
}

variable "publisherName" {
  description = "The name of the owner of the service"
  type        = string
}

variable "sku" {
  description = "The pricing tier of this API Management service"
  type        = string
  default     = "Developer"
}

variable "skuCount" {
  description = "The instance size of this API Management service."
  type        = number
  default     = 1
}

variable "location" {
  description = "Location for all resources."
  type        = string
  default     = "eastus"
}

variable "aoaiPrimaryAccount" {
  description = "Primary Azure OpenAI account"
  type        = string
}

variable "aoaiSecondaryAccount" {
  description = "Secondary Azure OpenAI account"
  type        = string
}

variable "aoaiPrimaryLLMDeployment" {
  description = "Primary LLM deployment"
  type        = string
}

variable "aoaiSecondaryLLMDeployment" {
  description = "Secondary LLM deployment"
  type        = string
}

resource "azurerm_api_management" "apiManagementService" {
  name                = var.apiManagementServiceName
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_email     = var.publisherEmail
  publisher_name      = var.publisherName
  sku_name            = var.sku
  sku_capacity        = var.skuCount
}

resource "azurerm_api_management_backend" "primarybackend" {
  name                = "primary"
  api_management_name = azurerm_api_management.apiManagementService.name
  resource_group_name = azurerm_resource_group.rg.name
  url                 = "https://${var.aoaiPrimaryAccount}.openai.azure.com/openai/deployments/${var.aoaiPrimaryLLMDeployment}"
  protocol            = "http"
  description         = "Primary LLM deployment endpoint"
}

resource "azurerm_api_management_backend" "secondarybackend" {
  name                = "secondary"
  api_management_name = azurerm_api_management.apiManagementService.name
  resource_group_name = azurerm_resource_group.rg.name
  url                 = "https://${var.aoaiSecondaryAccount}.openai.azure.com/openai/deployments/${var.aoaiSecondaryLLMDeployment}"
  protocol            = "http"
  description         = "Secondary LLM deployment endpoint"
}

resource "azurerm_api_management_api" "api" {
  name                = "CompletionsAPI"
  api_management_name = azurerm_api_management.apiManagementService.name
  resource_group_name = azurerm_resource_group.rg.name
  revision            = "1"
  display_name        = "Completions API"
  path                = "openai"
  protocols           = ["https"]
  import {
    content_format = "openapi"
    content_value  = file("${path.module}/openapi.json")
  }
}

resource "azurerm_api_management_api_policy" "policy" {
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management.apiManagementService.name
  resource_group_name = azurerm_resource_group.rg.name
  xml_content         = file("${path.module}/policy.xml")
}
