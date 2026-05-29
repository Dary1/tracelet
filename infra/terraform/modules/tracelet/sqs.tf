resource "aws_sqs_queue" "bottle_ocean_dlq" {
  name                        = "${local.name_prefix}-bottle-ocean-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = var.bottle_queue_retention_seconds
}

resource "aws_sqs_queue" "bottle_ocean" {
  name                        = "${local.name_prefix}-bottle-ocean.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = var.bottle_queue_retention_seconds
  visibility_timeout_seconds  = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bottle_ocean_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "bottle_ocean_test_dlq" {
  name                        = "${local.name_prefix}-bottle-ocean-test-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = var.bottle_queue_retention_seconds
}

resource "aws_sqs_queue" "bottle_ocean_test" {
  name                        = "${local.name_prefix}-bottle-ocean-test.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = var.bottle_queue_retention_seconds
  visibility_timeout_seconds  = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bottle_ocean_test_dlq.arn
    maxReceiveCount     = 3
  })
}
