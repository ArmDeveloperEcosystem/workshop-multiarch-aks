
resource "azurerm_kubernetes_cluster" "k8s" {
  location            = azurerm_resource_group.rg.location
  name                = var.cluster_name
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix
  tags                = {
    Environment = "Demo"
  }
  default_node_pool {
    name       = "armpool"
    vm_size    = "standard_b2pls_v2"
    node_count = var.agent_count
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "amdcluster" {
  name                  = "amdpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s.id
  vm_size               = "standard_a2_v2"
  node_count            = var.agent_count

  tags = {
    Environment = "Demo"
  }
}
