resource "random_string" "random" {
  length           = 12
  special          = false
  upper            = false
}

resource "azurerm_container_registry" "acr" {
    name                = "${var.acr_name_prefix}${random_string.random.result}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku                 = "Basic"
    admin_enabled       = true
}

resource "azurerm_role_assignment" "acrrole" {
  principal_id                     = azurerm_kubernetes_cluster.k8s.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}