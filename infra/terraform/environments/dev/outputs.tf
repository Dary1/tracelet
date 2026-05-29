output "aws_region" {
  value = var.aws_region
}

output "cognito_user_pool_id" {
  value = module.tracelet.cognito_user_pool_id
}

output "cognito_user_pool_client_id" {
  value = module.tracelet.cognito_user_pool_client_id
}

output "cognito_hosted_ui_domain" {
  value = module.tracelet.cognito_hosted_ui_domain
}

output "google_sign_in_enabled" {
  value = module.tracelet.google_sign_in_enabled
}

output "apple_sign_in_enabled" {
  value = module.tracelet.apple_sign_in_enabled
}

output "http_api_url" {
  value = module.tracelet.http_api_url
}

output "websocket_api_url" {
  value = module.tracelet.websocket_api_url
}

output "bottle_queue_url" {
  value     = module.tracelet.bottle_queue_url
  sensitive = false
}

output "bottle_test_queue_url" {
  value     = module.tracelet.bottle_test_queue_url
  sensitive = false
}

output "dynamodb_table_names" {
  value = module.tracelet.dynamodb_table_names
}
