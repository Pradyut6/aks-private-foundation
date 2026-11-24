# AKS Private Foundation

Terraform provisions a private Azure Kubernetes Service cluster with Microsoft Entra access, a container registry, and Log Analytics for control-plane auditing. The verification workflow uses mocked AzureRM plans and needs no Azure credentials.

| Component | Configuration |
| --- | --- |
| AKS control plane | Private endpoint, private DNS, local accounts disabled |
| Identity | Entra operator group, Azure RBAC, OIDC and workload identity |
| Workers | Two to four system nodes, Azure CNI Overlay with Cilium |
| Registry | Standard ACR with admin and anonymous access disabled. Only the AKS kubelet gets the scoped image-pull role. |
| Audit trail | AKS API server and administrative audit logs, retained for 30 days |

## Verify locally

~~~sh
terraform init -backend=false -lockfile=readonly
terraform fmt -check -recursive
terraform validate
terraform test
~~~

## Deploy to Azure

Use Terraform 1.14, Azure CLI, kubectl, and kubelogin. The deploying identity must be able to create the resources and grant the registry role. Use an existing Entra security group for cluster operators. The private endpoint requires a client with private connectivity and working DNS to the AKS network. Plan that connectivity before deploying. The Standard tier and the worker nodes incur charges while provisioned.

~~~sh
az login
az account set --subscription "$SUBSCRIPTION_ID"
export TF_VAR_subscription_id="$SUBSCRIPTION_ID"
export TF_VAR_operator_group_id="$OPERATOR_GROUP_ID"
export TF_VAR_name="myaksdemo"
terraform init -lockfile=readonly
terraform plan -out=platform.tfplan
terraform apply platform.tfplan
~~~

The default backend is local for a disposable lab. Teams should configure an Azure Storage backend with Microsoft Entra authentication, restricted access, and state versioning before the first shared deployment. The Terraform state may contain sensitive resource configuration. For backend setup, see the [AzureRM backend documentation](https://developer.hashicorp.com/terraform/language/backend/azurerm).

From a machine with access to the private API and an authorized Entra account:

~~~sh
az aks get-credentials --resource-group "$(terraform output -raw resource_group)" \
  --name "$(terraform output -raw cluster_name)"
kubelogin convert-kubeconfig -l azurecli
kubectl get nodes
az aks check-acr --resource-group "$(terraform output -raw resource_group)" \
  --name "$(terraform output -raw cluster_name)" \
  --acr "$(terraform output -raw registry_login_server)"
~~~

## Troubleshooting

- **API timeout**. Verify private DNS resolution and routing from the client to the AKS API endpoint. GitHub-hosted runners only run Terraform verification.
- **Access denied**. Check the Azure CLI tenant, account, and operator group membership. Obtain a fresh sign-in token if group membership recently changed.
- **Image pull denied**. Check the image path and tag, then verify the kubelet principal's scoped registry assignment. Azure role changes can take time to propagate. [AKS and ACR integration](https://learn.microsoft.com/en-us/azure/aks/cluster-container-registry-integration)
- **Audit review**. Query the `AKSAuditAdmin` and `AKSControlPlane` tables in the linked Log Analytics workspace after log ingestion.
- **Teardown**. Run `terraform plan -destroy` against the lab state and inspect the target subscription and resources before running `terraform destroy`.
