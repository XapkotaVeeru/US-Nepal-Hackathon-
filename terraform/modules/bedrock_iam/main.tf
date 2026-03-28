# ===========================================================
# Bedrock IAM Module - AI Model Access
# ===========================================================

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name
}

# --- Bedrock Invoke Policy for Claude 3 Sonnet (Risk Classification) ---
resource "aws_iam_policy" "bedrock_claude" {
  name        = "${local.name_prefix}-bedrock-claude-invoke"
  description = "Allow invoking Claude 3 Sonnet for risk classification"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeClaude3Sonnet"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:${local.region}::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
          "arn:aws:bedrock:${local.region}::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
        ]
      }
    ]
  })
}

# --- Bedrock Invoke Policy for Titan Embeddings V2 (Similarity Matching) ---
resource "aws_iam_policy" "bedrock_titan" {
  name        = "${local.name_prefix}-bedrock-titan-invoke"
  description = "Allow invoking Titan Embeddings V2 for similarity matching"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeTitanEmbeddings"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:${local.region}::foundation-model/amazon.titan-embed-text-v2:0"
        ]
      }
    ]
  })
}

# --- Outputs ---
output "bedrock_claude_policy_arn" {
  value = aws_iam_policy.bedrock_claude.arn
}

output "bedrock_titan_policy_arn" {
  value = aws_iam_policy.bedrock_titan.arn
}
