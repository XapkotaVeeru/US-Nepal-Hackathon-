# ===========================================================
# CloudWatch Module - Observability
# ===========================================================

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "enable_alarms" {
  type    = bool
  default = true
}

variable "lambda_function_names" {
  type = list(string)
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- Lambda Log Groups ---
resource "aws_cloudwatch_log_group" "lambda" {
  for_each          = toset(var.lambda_function_names)
  name              = "/aws/lambda/${each.value}"
  retention_in_days = var.log_retention_days
  tags = { Name = each.value }
}

# --- CloudWatch Dashboard ---
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "Lambda Errors"
          metrics = [for fn in var.lambda_function_names : ["AWS/Lambda", "Errors", "FunctionName", fn]]
          period  = 300, stat = "Sum", region = data.aws_region.current.name
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title   = "Lambda Duration"
          metrics = [for fn in var.lambda_function_names : ["AWS/Lambda", "Duration", "FunctionName", fn]]
          period  = 300, stat = "Average", region = data.aws_region.current.name
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title = "ECS CPU Utilization"
          metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]]
          period = 300, stat = "Average", region = data.aws_region.current.name
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title = "ECS Memory Utilization"
          metrics = [["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]]
          period = 300, stat = "Average", region = data.aws_region.current.name
        }
      },
      {
        type = "metric", x = 0, y = 12, width = 12, height = 6
        properties = {
          title   = "DynamoDB Read Throttles"
          metrics = [
            ["AWS/DynamoDB", "ReadThrottleEvents", "TableName", "${local.name_prefix}-posts"],
            ["AWS/DynamoDB", "ReadThrottleEvents", "TableName", "${local.name_prefix}-messages"],
            ["AWS/DynamoDB", "ReadThrottleEvents", "TableName", "${local.name_prefix}-users"]
          ]
          period = 300, stat = "Sum", region = data.aws_region.current.name
        }
      },
      {
        type = "metric", x = 12, y = 12, width = 12, height = 6
        properties = {
          title   = "Lambda Invocations"
          metrics = [for fn in var.lambda_function_names : ["AWS/Lambda", "Invocations", "FunctionName", fn]]
          period  = 300, stat = "Sum", region = data.aws_region.current.name
        }
      }
    ]
  })
}

data "aws_region" "current" {}

# --- SNS Topic for Alarms ---
resource "aws_sns_topic" "alarms" {
  count = var.enable_alarms ? 1 : 0
  name  = "${local.name_prefix}-alarms"
  tags  = { Name = "${local.name_prefix}-alarms" }
}

# --- Lambda Error Rate Alarm ---
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${local.name_prefix}-lambda-high-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Lambda error rate exceeded threshold"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]
  treat_missing_data  = "notBreaching"
  tags = { Name = "${local.name_prefix}-lambda-errors-alarm" }
}

# --- ECS CPU Alarm ---
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${local.name_prefix}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS CPU above 80%"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
  tags = { Name = "${local.name_prefix}-ecs-cpu-alarm" }
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alarms_topic_arn" {
  value = var.enable_alarms ? aws_sns_topic.alarms[0].arn : ""
}
