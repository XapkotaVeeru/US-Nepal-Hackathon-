# ===========================================================
# EventBridge Module - Scheduled Tasks
# ===========================================================

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "insights_schedule" {
  type    = string
  default = "cron(0 2 * * ? *)"
}

variable "matching_schedule" {
  type    = string
  default = "rate(6 hours)"
}

variable "cleanup_schedule" {
  type    = string
  default = "rate(24 hours)"
}

variable "insights_aggregator_arn" {
  type = string
}

variable "match_users_arn" {
  type = string
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_cloudwatch_event_rule" "insights" {
  name                = "${local.name_prefix}-daily-insights"
  description         = "Daily insights aggregation at 2 AM UTC"
  schedule_expression = var.insights_schedule
  tags = { Name = "${local.name_prefix}-daily-insights" }
}

resource "aws_cloudwatch_event_target" "insights" {
  rule = aws_cloudwatch_event_rule.insights.name
  arn  = var.insights_aggregator_arn
  input = jsonencode({ source = "eventbridge", action = "aggregate_daily_insights" })
}

resource "aws_lambda_permission" "insights_eb" {
  statement_id  = "AllowEBInsights"
  action        = "lambda:InvokeFunction"
  function_name = var.insights_aggregator_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.insights.arn
}

resource "aws_cloudwatch_event_rule" "matching" {
  name                = "${local.name_prefix}-auto-matching"
  description         = "Auto-matching every 6 hours"
  schedule_expression = var.matching_schedule
  tags = { Name = "${local.name_prefix}-auto-matching" }
}

resource "aws_cloudwatch_event_target" "matching" {
  rule = aws_cloudwatch_event_rule.matching.name
  arn  = var.match_users_arn
  input = jsonencode({ source = "eventbridge", action = "auto_match_users" })
}

resource "aws_lambda_permission" "matching_eb" {
  statement_id  = "AllowEBMatching"
  action        = "lambda:InvokeFunction"
  function_name = var.match_users_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.matching.arn
}

resource "aws_cloudwatch_event_rule" "cleanup" {
  name                = "${local.name_prefix}-cleanup"
  description         = "Cleanup expired posts/sessions every 24 hours"
  schedule_expression = var.cleanup_schedule
  tags = { Name = "${local.name_prefix}-cleanup" }
}

resource "aws_cloudwatch_event_target" "cleanup" {
  rule = aws_cloudwatch_event_rule.cleanup.name
  arn  = var.insights_aggregator_arn
  input = jsonencode({ source = "eventbridge", action = "cleanup_expired" })
}

resource "aws_lambda_permission" "cleanup_eb" {
  statement_id  = "AllowEBCleanup"
  action        = "lambda:InvokeFunction"
  function_name = var.insights_aggregator_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cleanup.arn
}

output "insights_rule_arn" { value = aws_cloudwatch_event_rule.insights.arn }
output "matching_rule_arn" { value = aws_cloudwatch_event_rule.matching.arn }
output "cleanup_rule_arn" { value = aws_cloudwatch_event_rule.cleanup.arn }
