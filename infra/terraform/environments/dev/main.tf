module "tracelet" {
  source = "../../modules/tracelet"

  aws_region                     = var.aws_region
  environment                    = var.environment
  project_name                   = var.project_name
  bottle_queue_retention_seconds = var.bottle_queue_retention_seconds
  pending_direct_ttl_seconds     = var.pending_direct_ttl_seconds
  presence_ttl_seconds           = var.presence_ttl_seconds
  google_client_id               = var.google_client_id
  google_client_secret           = var.google_client_secret
  apple_services_id              = var.apple_services_id
  apple_team_id                  = var.apple_team_id
  apple_key_id                   = var.apple_key_id
  apple_private_key              = var.apple_private_key
  oauth_redirect_uri             = var.oauth_redirect_uri
}