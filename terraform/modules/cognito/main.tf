# ===========================================================
# Cognito Module - Anonymous Identity Pool
# ===========================================================

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "api_gateway_execution_arn" {
  type    = string
  default = ""
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- Cognito Identity Pool (Unauthenticated Access) ---
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${local.name_prefix}-anonymous-pool"
  allow_unauthenticated_identities = true
  allow_classic_flow                = true

  tags = {
    Name = "${local.name_prefix}-identity-pool"
  }
}

# --- Unauthenticated IAM Role ---
data "aws_iam_policy_document" "cognito_unauth_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.main.id]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["unauthenticated"]
    }
  }
}

resource "aws_iam_role" "cognito_unauth" {
  name               = "${local.name_prefix}-cognito-unauth-role"
  assume_role_policy = data.aws_iam_policy_document.cognito_unauth_assume.json

  tags = {
    Name = "${local.name_prefix}-cognito-unauth-role"
  }
}

# Unauthenticated users can ONLY invoke API Gateway - no direct AWS SDK calls
resource "aws_iam_role_policy" "cognito_unauth" {
  name = "${local.name_prefix}-cognito-unauth-policy"
  role = aws_iam_role.cognito_unauth.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = [
          "arn:aws:execute-api:*:*:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "mobileanalytics:PutEvents",
          "cognito-sync:*",
          "cognito-identity:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- Attach Role to Identity Pool ---
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "unauthenticated" = aws_iam_role.cognito_unauth.arn
  }
}

# --- Outputs ---
output "identity_pool_id" {
  value = aws_cognito_identity_pool.main.id
}

output "identity_pool_arn" {
  value = aws_cognito_identity_pool.main.arn
}

output "unauth_role_arn" {
  value = aws_iam_role.cognito_unauth.arn
}
