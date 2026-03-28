# ===========================================================
# Lambda Module - All Serverless Functions
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

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "timeout" {
  type    = number
  default = 30
}

variable "memory_size" {
  type    = number
  default = 256
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "lambda_security_group_id" {
  type = string
}

# IAM Role ARNs
variable "create_post_role_arn" {
  type = string
}

variable "classify_risk_role_arn" {
  type = string
}

variable "match_users_role_arn" {
  type = string
}

variable "join_community_role_arn" {
  type = string
}

variable "send_message_role_arn" {
  type = string
}

variable "get_messages_role_arn" {
  type = string
}

variable "discover_communities_role_arn" {
  type = string
}

variable "insights_aggregator_role_arn" {
  type = string
}

variable "send_push_notification_role_arn" {
  type = string
}

variable "websocket_handler_role_arn" {
  type = string
}

variable "presigned_url_role_arn" {
  type = string
}

# DynamoDB Table Names
variable "users_table_name" {
  type = string
}

variable "posts_table_name" {
  type = string
}

variable "messages_table_name" {
  type = string
}

variable "communities_table_name" {
  type = string
}

variable "matches_table_name" {
  type = string
}

variable "embeddings_table_name" {
  type = string
}

variable "connections_table_name" {
  type = string
}

# Stream ARNs
variable "posts_stream_arn" {
  type = string
}

variable "messages_stream_arn" {
  type = string
}

# Other
variable "media_bucket_name" {
  type = string
}

variable "crisis_alerts_topic_arn" {
  type = string
}

variable "fcm_parameter_name" {
  type = string
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_env_vars = {
    ENVIRONMENT        = var.environment
    PROJECT_NAME       = var.project_name
    AWS_REGION_NAME    = var.aws_region
    USERS_TABLE        = var.users_table_name
    POSTS_TABLE        = var.posts_table_name
    MESSAGES_TABLE     = var.messages_table_name
    COMMUNITIES_TABLE  = var.communities_table_name
    MATCHES_TABLE      = var.matches_table_name
    EMBEDDINGS_TABLE   = var.embeddings_table_name
    CONNECTIONS_TABLE  = var.connections_table_name
    MEDIA_BUCKET       = var.media_bucket_name
    CRISIS_TOPIC_ARN   = var.crisis_alerts_topic_arn
    FCM_PARAMETER_NAME = var.fcm_parameter_name
  }
}

# === Lambda source archives ===
data "archive_file" "create_post_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda/create_post"
  output_path = "${path.module}/create_post.zip"
}

data "archive_file" "classify_risk_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda/classify_risk"
  output_path = "${path.module}/classify_risk.zip"
}

data "archive_file" "match_users_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda/match_users"
  output_path = "${path.module}/match_users.zip"
}

# --- Placeholder Lambda Deployment Package ---
data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"

  source {
    content  = <<-EOF
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps({
            'message': 'Function placeholder - deploy actual code',
            'function': context.function_name
        })
    }
EOF
    filename = "lambda_function.py"
  }
}

# ==================== createPost ====================
resource "aws_lambda_function" "create_post" {
  function_name = "${local.name_prefix}-createPost"
  role          = var.create_post_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  filename      = data.archive_file.create_post_zip.output_path
  source_code_hash = data.archive_file.create_post_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "createPost"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-createPost"
    Function = "createPost"
  }
}

# ==================== classifyRisk ====================
resource "aws_lambda_function" "classify_risk" {
  function_name = "${local.name_prefix}-classifyRisk"
  role          = var.classify_risk_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = 60
  memory_size   = 512
  filename      = data.archive_file.classify_risk_zip.output_path
  source_code_hash = data.archive_file.classify_risk_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME       = "classifyRisk"
      BEDROCK_MODEL_ID    = "anthropic.claude-3-sonnet-20240229-v1:0"
      MATCH_FUNCTION_NAME = "${local.name_prefix}-matchUsers"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-classifyRisk"
    Function = "classifyRisk"
  }
}

# DynamoDB Stream trigger for classifyRisk
resource "aws_lambda_event_source_mapping" "posts_stream_classify" {
  event_source_arn  = var.posts_stream_arn
  function_name     = aws_lambda_function.classify_risk.arn
  starting_position = "LATEST"
  batch_size        = 10

  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName = ["INSERT"]
      })
    }
  }
}

# ==================== matchUsers ====================
resource "aws_lambda_function" "match_users" {
  function_name = "${local.name_prefix}-matchUsers"
  role          = var.match_users_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = 120
  memory_size   = 512
  filename      = data.archive_file.match_users_zip.output_path
  source_code_hash = data.archive_file.match_users_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME    = "matchUsers"
      BEDROCK_MODEL_ID = "amazon.titan-embed-text-v2:0"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-matchUsers"
    Function = "matchUsers"
  }
}

# ==================== joinCommunity ====================
resource "aws_lambda_function" "join_community" {
  function_name = "${local.name_prefix}-joinCommunity"
  role          = var.join_community_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  filename      = data.archive_file.lambda_placeholder.output_path

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "joinCommunity"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-joinCommunity"
    Function = "joinCommunity"
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# ==================== sendMessage ====================
resource "aws_lambda_function" "send_message" {
  function_name = "${local.name_prefix}-sendMessage"
  role          = var.send_message_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  filename      = data.archive_file.lambda_placeholder.output_path

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "sendMessage"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-sendMessage"
    Function = "sendMessage"
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# ==================== getMessages ====================
resource "aws_lambda_function" "get_messages" {
  function_name = "${local.name_prefix}-getMessages"
  role          = var.get_messages_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  filename      = data.archive_file.lambda_placeholder.output_path

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "getMessages"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-getMessages"
    Function = "getMessages"
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# ==================== discoverCommunities ====================
resource "aws_lambda_function" "discover_communities" {
  function_name = "${local.name_prefix}-discoverCommunities"
  role          = var.discover_communities_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  filename      = data.archive_file.lambda_placeholder.output_path

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "discoverCommunities"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-discoverCommunities"
    Function = "discoverCommunities"
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# ==================== insightsAggregator ====================
resource "aws_lambda_function" "insights_aggregator" {
  function_name = "${local.name_prefix}-insightsAggregator"
  role          = var.insights_aggregator_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = 300
  memory_size   = 512
  filename      = data.archive_file.lambda_placeholder.output_path

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "insightsAggregator"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-insightsAggregator"
    Function = "insightsAggregator"
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# ==================== sendPushNotification ====================
resource "aws_lambda_function" "send_push_notification" {
  function_name = "${local.name_prefix}-sendPushNotification"
  role          = var.send_push_notification_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  filename      = data.archive_file.lambda_placeholder.output_path

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "sendPushNotification"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-sendPushNotification"
    Function = "sendPushNotification"
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# ==================== WebSocket Connect Handler ====================
resource "aws_lambda_function" "ws_connect" {
  function_name = "${local.name_prefix}-wsConnect"
  role          = var.websocket_handler_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = 128
  filename      = data.archive_file.lambda_placeholder.output_path

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "wsConnect"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-wsConnect"
    Function = "wsConnect"
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# ==================== WebSocket Disconnect Handler ====================
resource "aws_lambda_function" "ws_disconnect" {
  function_name = "${local.name_prefix}-wsDisconnect"
  role          = var.websocket_handler_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = 128
  filename      = data.archive_file.lambda_placeholder.output_path

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "wsDisconnect"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-wsDisconnect"
    Function = "wsDisconnect"
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# ==================== WebSocket Default Handler ====================
resource "aws_lambda_function" "ws_default" {
  function_name = "${local.name_prefix}-wsDefault"
  role          = var.send_message_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = 256
  filename      = data.archive_file.lambda_placeholder.output_path

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "wsDefault"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-wsDefault"
    Function = "wsDefault"
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# ==================== Presigned URL Generator ====================
resource "aws_lambda_function" "presigned_url" {
  function_name = "${local.name_prefix}-presignedUrl"
  role          = var.presigned_url_role_arn
  handler       = "lambda_function.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = 128
  filename      = data.archive_file.lambda_placeholder.output_path

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "presignedUrl"
    })
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name     = "${local.name_prefix}-presignedUrl"
    Function = "presignedUrl"
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# --- Outputs ---
output "create_post_arn" {
  value = aws_lambda_function.create_post.arn
}

output "create_post_invoke_arn" {
  value = aws_lambda_function.create_post.invoke_arn
}

output "classify_risk_arn" {
  value = aws_lambda_function.classify_risk.arn
}

output "match_users_arn" {
  value = aws_lambda_function.match_users.arn
}

output "match_users_invoke_arn" {
  value = aws_lambda_function.match_users.invoke_arn
}

output "join_community_arn" {
  value = aws_lambda_function.join_community.arn
}

output "join_community_invoke_arn" {
  value = aws_lambda_function.join_community.invoke_arn
}

output "send_message_arn" {
  value = aws_lambda_function.send_message.arn
}

output "send_message_invoke_arn" {
  value = aws_lambda_function.send_message.invoke_arn
}

output "get_messages_arn" {
  value = aws_lambda_function.get_messages.arn
}

output "get_messages_invoke_arn" {
  value = aws_lambda_function.get_messages.invoke_arn
}

output "discover_communities_arn" {
  value = aws_lambda_function.discover_communities.arn
}

output "discover_communities_invoke_arn" {
  value = aws_lambda_function.discover_communities.invoke_arn
}

output "insights_aggregator_arn" {
  value = aws_lambda_function.insights_aggregator.arn
}

output "insights_aggregator_invoke_arn" {
  value = aws_lambda_function.insights_aggregator.invoke_arn
}

output "send_push_notification_arn" {
  value = aws_lambda_function.send_push_notification.arn
}

output "send_push_notification_invoke_arn" {
  value = aws_lambda_function.send_push_notification.invoke_arn
}

output "ws_connect_arn" {
  value = aws_lambda_function.ws_connect.arn
}

output "ws_connect_invoke_arn" {
  value = aws_lambda_function.ws_connect.invoke_arn
}

output "ws_disconnect_arn" {
  value = aws_lambda_function.ws_disconnect.arn
}

output "ws_disconnect_invoke_arn" {
  value = aws_lambda_function.ws_disconnect.invoke_arn
}

output "ws_default_arn" {
  value = aws_lambda_function.ws_default.arn
}

output "ws_default_invoke_arn" {
  value = aws_lambda_function.ws_default.invoke_arn
}

output "presigned_url_arn" {
  value = aws_lambda_function.presigned_url.arn
}

output "presigned_url_invoke_arn" {
  value = aws_lambda_function.presigned_url.invoke_arn
}

output "all_function_names" {
  value = [
    aws_lambda_function.create_post.function_name,
    aws_lambda_function.classify_risk.function_name,
    aws_lambda_function.match_users.function_name,
    aws_lambda_function.join_community.function_name,
    aws_lambda_function.send_message.function_name,
    aws_lambda_function.get_messages.function_name,
    aws_lambda_function.discover_communities.function_name,
    aws_lambda_function.insights_aggregator.function_name,
    aws_lambda_function.send_push_notification.function_name,
    aws_lambda_function.ws_connect.function_name,
    aws_lambda_function.ws_disconnect.function_name,
    aws_lambda_function.ws_default.function_name,
    aws_lambda_function.presigned_url.function_name,
  ]
}
