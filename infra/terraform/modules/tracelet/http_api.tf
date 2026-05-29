resource "aws_apigatewayv2_api" "http" {
  name          = "${local.name_prefix}-http"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "api" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "settings_get" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "GET /settings"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "settings_put" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "PUT /settings"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "direct_send" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "POST /messages/direct"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "direct_fetch" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "POST /messages/direct/fetch"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "bottle_deposit" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "POST /bottles"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "bottle_pull" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "POST /bottles/pull"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "friends_list" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "GET /friends"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "friends_add" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "POST /friends"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "friends_delete" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "DELETE /friends"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "friends_name_trace" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "PUT /friends/name-trace"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_stage" "http" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = var.environment
  auto_deploy = true
}

resource "aws_apigatewayv2_authorizer" "http" {
  api_id           = aws_apigatewayv2_api.http.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.mobile.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
  }
}
