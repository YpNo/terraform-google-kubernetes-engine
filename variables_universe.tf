###############################################################################
# Universe — Google Cloud Dedicated / sovereign universes (non-googleapis.com).
#
# In a dedicated universe the API endpoints AND service-agent email domains
# differ. The API endpoints are handled entirely by the provider: the CALLER
# sets `universe_domain` on the google / google-beta providers (this module
# configures no providers). What the module cannot get from the provider is the
# GKE service-agent email it grants KMS access to — set `universe` here so that
# email is constructed with the universe-specific domain
# (service-<n>@container-engine-robot.<prefix>-system.iam.gserviceaccount.com).
#
# Leave null for the public googleapis.com universe.
###############################################################################

variable "universe" {
  description = "Dedicated/sovereign universe settings. Null = public googleapis.com universe. When set, the caller must also set universe_domain on the google/google-beta providers."
  type = object({
    prefix = string # Universe prefix, e.g. the '<prefix>' in '<prefix>-system.iam.gserviceaccount.com'
  })
  default = null
}
