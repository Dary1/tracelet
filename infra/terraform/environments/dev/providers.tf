provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "tracelet"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
