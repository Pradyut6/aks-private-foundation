output "resource_group" {
  value = azurerm_resource_group.platform.name
}
output "cluster_name" {
  value = azurerm_kubernetes_cluster.platform.name
}
output "registry_login_server" {
  value = azurerm_container_registry.images.login_server
}
output "oidc_issuer" {
  value = azurerm_kubernetes_cluster.platform.oidc_issuer_url
}
