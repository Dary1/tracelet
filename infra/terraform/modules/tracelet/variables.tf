variable "aws_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "bottle_queue_retention_seconds" {
  type = number
}

variable "pending_direct_ttl_seconds" {
  type = number
}

variable "presence_ttl_seconds" {
  type = number
}

variable "google_client_id" {
  type    = string
  default = ""
}

variable "google_client_secret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "apple_services_id" {
  type    = string
  default = ""
}

variable "apple_team_id" {
  type    = string
  default = ""
}

variable "apple_key_id" {
  type    = string
  default = ""
}

variable "apple_private_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "oauth_redirect_uri" {
  type    = string
  default = "tracelet://auth/callback"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}
