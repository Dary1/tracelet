output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.mobile.id
}

output "cognito_hosted_ui_domain" {
  value = "${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "google_sign_in_enabled" {
  value = var.google_client_id != ""
}

output "apple_sign_in_enabled" {
  value = var.apple_services_id != ""
}

output "http_api_url" {
  value = aws_apigatewayv2_stage.http.invoke_url
}

output "websocket_api_url" {
  value = replace(aws_apigatewayv2_stage.websocket.invoke_url, "https://", "wss://")
}

output "bottle_queue_url" {
  value = aws_sqs_queue.bottle_ocean.url
}

output "bottle_test_queue_url" {
  value = aws_sqs_queue.bottle_ocean_test.url
}

output "dynamodb_table_names" {
  value = {
    users          = aws_dynamodb_table.users.name
    friendships    = aws_dynamodb_table.friendships.name
    presence       = aws_dynamodb_table.presence.name
    pending_direct = aws_dynamodb_table.pending_direct.name
    connections    = aws_dynamodb_table.connections.name
  }
}
