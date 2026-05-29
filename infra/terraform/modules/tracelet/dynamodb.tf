resource "aws_dynamodb_table" "users" {
  name         = "${local.name_prefix}-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_dynamodb_table" "friendships" {
  name         = "${local.name_prefix}-friendships"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "friendUserId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "friendUserId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "presence" {
  name         = "${local.name_prefix}-presence"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }
}

resource "aws_dynamodb_table" "pending_direct" {
  name         = "${local.name_prefix}-pending-direct"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "recipientUserId"
  range_key    = "messageId"

  attribute {
    name = "recipientUserId"
    type = "S"
  }

  attribute {
    name = "messageId"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }
}

resource "aws_dynamodb_table" "connections" {
  name         = "${local.name_prefix}-connections"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }
}
