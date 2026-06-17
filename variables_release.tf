###############################################################################
# Release — GKE release channel. Gateway API channel is enforced in locals.tf.
###############################################################################

variable "release_channel" {
  description = "The GKE release channel to subscribe to."
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE", "EXTENDED"], var.release_channel)
    error_message = "release_channel must be one of RAPID, REGULAR, STABLE or EXTENDED."
  }
}
