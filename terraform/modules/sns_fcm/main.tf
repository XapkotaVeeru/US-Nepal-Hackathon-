# ===========================================================
# SNS FCM Module - Push Notifications
# ===========================================================

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "fcm_server_key_parameter_name" {
  type = string
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- SSM Parameter for FCM Server Key ---
# The actual value must be set manually via AWS Console or CLI:
# aws ssm put-parameter --name "/mindconnect/fcm/server-key" \
#   --value "YOUR_FCM_SERVER_KEY" --type SecureString
resource "aws_ssm_parameter" "fcm_server_key" {
  name        = var.fcm_server_key_parameter_name
  description = "Firebase Cloud Messaging server key for push notifications"
  type        = "SecureString"
  value       = "PLACEHOLDER_REPLACE_VIA_CLI"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name = "${local.name_prefix}-fcm-server-key"
  }
}

# --- SNS Topic for Crisis Alerts ---
resource "aws_sns_topic" "crisis_alerts" {
  name = "${local.name_prefix}-crisis-alerts"

  tags = {
    Name = "${local.name_prefix}-crisis-alerts"
  }
}

# --- SNS Topic for Community Notifications ---
resource "aws_sns_topic" "community_notifications" {
  name = "${local.name_prefix}-community-notifications"

  tags = {
    Name = "${local.name_prefix}-community-notifications"
  }
}

# --- SNS Topic for General Notifications ---
resource "aws_sns_topic" "general_notifications" {
  name = "${local.name_prefix}-general-notifications"

  tags = {
    Name = "${local.name_prefix}-general-notifications"
  }
}

# --- SNS Topic Policy ---
resource "aws_sns_topic_policy" "crisis_alerts" {
  arn = aws_sns_topic.crisis_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.crisis_alerts.arn
      }
    ]
  })
}

# --- Outputs ---
output "crisis_alerts_topic_arn" {
  value = aws_sns_topic.crisis_alerts.arn
}

output "community_notifications_topic_arn" {
  value = aws_sns_topic.community_notifications.arn
}

output "general_notifications_topic_arn" {
  value = aws_sns_topic.general_notifications.arn
}

output "fcm_parameter_name" {
  value = aws_ssm_parameter.fcm_server_key.name
}

output "fcm_parameter_arn" {
  value = aws_ssm_parameter.fcm_server_key.arn
}
