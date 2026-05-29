variable "aws_region" {
  description = "Primary AWS region (Tokyo for Japan)."
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Short project name used in resource names."
  type        = string
  default     = "tracelet"
}

variable "bottle_queue_retention_seconds" {
  description = "SQS retention for unclaimed bottle messages (24 hours)."
  type        = number
  default     = 86400
}

variable "pending_direct_ttl_seconds" {
  description = "DynamoDB TTL for unread direct messages (24 hours)."
  type        = number
  default     = 86400
}

variable "presence_ttl_seconds" {
  description = "DynamoDB TTL for live-session presence heartbeats."
  type        = number
  default     = 60
}

variable "google_client_id" {
  description = "Google OAuth web client ID for Cognito federated sign-in."
  type        = string
  default     = ""
}

variable "google_client_secret" {
  description = "Google OAuth web client secret for Cognito federated sign-in."
  type        = string
  default     = ""
  sensitive   = true
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
