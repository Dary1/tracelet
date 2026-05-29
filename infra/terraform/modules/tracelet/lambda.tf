locals {
  lambda_env = {
    USERS_TABLE          = aws_dynamodb_table.users.name
    FRIENDSHIPS_TABLE    = aws_dynamodb_table.friendships.name
    PRESENCE_TABLE       = aws_dynamodb_table.presence.name
    PENDING_DIRECT_TABLE = aws_dynamodb_table.pending_direct.name
    CONNECTIONS_TABLE    = aws_dynamodb_table.connections.name
    BOTTLE_QUEUE_URL      = aws_sqs_queue.bottle_ocean.url
    BOTTLE_TEST_QUEUE_URL = aws_sqs_queue.bottle_ocean_test.url
    PRESENCE_TTL_SECONDS = tostring(var.presence_ttl_seconds)
    PENDING_TTL_SECONDS  = tostring(var.pending_direct_ttl_seconds)
    WEBSOCKET_ENDPOINT   = "https://${aws_apigatewayv2_api.websocket.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_apigatewayv2_stage.websocket.name}"
  }
}

data "archive_file" "ws_connect" {
  type        = "zip"
  source_file = "${path.module}/../../../lambda/ws-connect/index.js"
  output_path = "${path.module}/build/ws-connect.zip"
}

data "archive_file" "ws_disconnect" {
  type        = "zip"
  source_file = "${path.module}/../../../lambda/ws-disconnect/index.js"
  output_path = "${path.module}/build/ws-disconnect.zip"
}

data "archive_file" "ws_relay" {
  type        = "zip"
  source_file = "${path.module}/../../../lambda/ws-relay/index.js"
  output_path = "${path.module}/build/ws-relay.zip"
}

data "archive_file" "api" {
  type        = "zip"
  source_file = "${path.module}/../../../lambda/api/index.js"
  output_path = "${path.module}/build/api.zip"
}

resource "aws_lambda_function" "ws_connect" {
  function_name = "${local.name_prefix}-ws-connect"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 10
  filename      = data.archive_file.ws_connect.output_path
  source_code_hash = data.archive_file.ws_connect.output_base64sha256

  environment {
    variables = local.lambda_env
  }
}

resource "aws_lambda_function" "ws_disconnect" {
  function_name = "${local.name_prefix}-ws-disconnect"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 10
  filename      = data.archive_file.ws_disconnect.output_path
  source_code_hash = data.archive_file.ws_disconnect.output_base64sha256

  environment {
    variables = local.lambda_env
  }
}

resource "aws_lambda_function" "ws_relay" {
  function_name = "${local.name_prefix}-ws-relay"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 10
  filename      = data.archive_file.ws_relay.output_path
  source_code_hash = data.archive_file.ws_relay.output_base64sha256

  environment {
    variables = local.lambda_env
  }
}

resource "aws_lambda_function" "api" {
  function_name = "${local.name_prefix}-api"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 15
  filename      = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256

  environment {
    variables = local.lambda_env
  }
}

resource "aws_cloudwatch_log_group" "ws_connect" {
  name              = "/aws/lambda/${aws_lambda_function.ws_connect.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ws_disconnect" {
  name              = "/aws/lambda/${aws_lambda_function.ws_disconnect.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ws_relay" {
  name              = "/aws/lambda/${aws_lambda_function.ws_relay.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/${aws_lambda_function.api.function_name}"
  retention_in_days = 14
}

resource "aws_lambda_permission" "ws_connect" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ws_connect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "ws_disconnect" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ws_disconnect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "ws_relay" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ws_relay.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
