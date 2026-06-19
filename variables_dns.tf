###############################################################################
# DNS — Cloud DNS provider/scope for the cluster (Standard clusters only).
# dns_cache and dns_allow_external_traffic are enforced in locals.tf.
###############################################################################

variable "cluster_dns_provider" {
  description = "DNS provider for the cluster. One of PROVIDER_UNSPECIFIED, PLATFORM_DEFAULT, CLOUD_DNS."
  type        = string
  default     = "PROVIDER_UNSPECIFIED"

  validation {
    condition     = contains(["PROVIDER_UNSPECIFIED", "PLATFORM_DEFAULT", "CLOUD_DNS"], var.cluster_dns_provider)
    error_message = "cluster_dns_provider must be PROVIDER_UNSPECIFIED, PLATFORM_DEFAULT or CLOUD_DNS."
  }
}

variable "cluster_dns_scope" {
  description = "DNS scope for the cluster. One of DNS_SCOPE_UNSPECIFIED, CLUSTER_SCOPE, VPC_SCOPE."
  type        = string
  default     = "DNS_SCOPE_UNSPECIFIED"

  validation {
    condition     = contains(["DNS_SCOPE_UNSPECIFIED", "CLUSTER_SCOPE", "VPC_SCOPE"], var.cluster_dns_scope)
    error_message = "cluster_dns_scope must be DNS_SCOPE_UNSPECIFIED, CLUSTER_SCOPE or VPC_SCOPE."
  }
}
