mock_provider "azurerm" {}

variables {
  subscription_id   = "00000000-0000-4000-8000-000000000001"
  operator_group_id = "00000000-0000-4000-8000-000000000002"
  name              = "platformtest"
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.platform.private_cluster_enabled && !azurerm_kubernetes_cluster.platform.private_cluster_public_fqdn_enabled && azurerm_kubernetes_cluster.platform.local_account_disabled
    error_message = "The API must be private and local credentials disabled."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.platform.oidc_issuer_enabled && azurerm_kubernetes_cluster.platform.workload_identity_enabled && azurerm_kubernetes_cluster.platform.azure_active_directory_role_based_access_control[0].azure_rbac_enabled
    error_message = "Enable workload federation and Entra authorization."
  }

  assert {
    condition     = !azurerm_container_registry.images.admin_enabled && !azurerm_container_registry.images.anonymous_pull_enabled && azurerm_role_assignment.image_pull.role_definition_name == "AcrPull"
    error_message = "Image pulls must use scoped identity instead of registry credentials."
  }
  assert {
    condition     = contains([for log in azurerm_monitor_diagnostic_setting.control_plane.enabled_log : log.category], "kube-audit-admin") && azurerm_log_analytics_workspace.platform.retention_in_days >= 30
    error_message = "Retain administrative audit logs for at least 30 days."
  }
}
