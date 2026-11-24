variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "location" {
  type        = string
  description = "Azure region supporting the selected AKS node SKU."
  default     = "eastus2"
}

variable "name" {
  type        = string
  description = "Lowercase platform prefix, also used to generate the registry name."
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{3,19}$", var.name))
    error_message = "Use 4–20 lowercase letters or digits, starting with a letter."
  }
}

variable "operator_group_id" {
  type        = string
  description = "Microsoft Entra security group object ID for cluster operators."
}

variable "node_size" {
  type        = string
  description = "Azure VM SKU for the system node pool."
  default     = "Standard_D4s_v5"
}
