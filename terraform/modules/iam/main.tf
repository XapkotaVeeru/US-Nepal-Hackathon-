# ===========================================================
# IAM Module - Least Privilege Roles
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

variable "users_table_arn" {
  type = string
}

variable "posts_table_arn" {
  type = string
}

variable "messages_table_arn" {
  type = string
}

variable "communities_table_arn" {
  type = string
}

variable "matches_table_arn" {
  type = string
}

variable "embeddings_table_arn" {
  type = string
}

variable "connections_table_arn" {
  type = string
}

variable "posts_stream_arn" {
  type = string
}

variable "messages_stream_arn" {
  type = string
}

variable "media_bucket_arn" {
  type = string
}

variable "logs_bucket_arn" {
  type = string
}

variable "sns_platform_app_arn" {
  type    = string
  default = ""
}

variable "api_gateway_execution_arn" {
  type    = string
  default = ""
}

variable "websocket_api_execution_arn" {
  type    = string
  default = ""
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name
}

# ===========================================================
# Lambda Execution Roles - Per Function Least Privilege
# ===========================================================

# --- Base Lambda Assume Role Policy ---
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# --- Common Lambda Logging Policy ---
resource "aws_iam_policy" "lambda_logging" {
  name        = "${local.name_prefix}-lambda-logging"
  description = "Allow Lambda to write CloudWatch logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${local.name_prefix}-*:*"
      }
    ]
  })
}

# --- Common Lambda VPC Policy ---
resource "aws_iam_policy" "lambda_vpc" {
  name        = "${local.name_prefix}-lambda-vpc"
  description = "Allow Lambda to manage VPC ENIs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==================== createPost Lambda Role ====================
resource "aws_iam_role" "lambda_create_post" {
  name               = "${local.name_prefix}-lambda-createPost"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "create_post" {
  name = "${local.name_prefix}-createPost-policy"
  role = aws_iam_role.lambda_create_post.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ]
        Resource = [
          var.posts_table_arn,
          "${var.posts_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem"
        ]
        Resource = var.users_table_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "create_post_logging" {
  role       = aws_iam_role.lambda_create_post.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "create_post_vpc" {
  role       = aws_iam_role.lambda_create_post.name
  policy_arn = aws_iam_policy.lambda_vpc.arn
}

# ==================== classifyRisk Lambda Role ====================
resource "aws_iam_role" "lambda_classify_risk" {
  name               = "${local.name_prefix}-lambda-classifyRisk"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "classify_risk" {
  name = "${local.name_prefix}-classifyRisk-policy"
  role = aws_iam_role.lambda_classify_risk.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          var.posts_table_arn,
          "${var.posts_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetStreams",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams",
          "dynamodb:GetRecords"
        ]
        Resource = var.posts_stream_arn
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "arn:aws:bedrock:${local.region}::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:${local.region}:${local.account_id}:function:${local.name_prefix}-matchUsers"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "arn:aws:sns:${local.region}:${local.account_id}:${local.name_prefix}-*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "classify_risk_logging" {
  role       = aws_iam_role.lambda_classify_risk.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "classify_risk_vpc" {
  role       = aws_iam_role.lambda_classify_risk.name
  policy_arn = aws_iam_policy.lambda_vpc.arn
}

# ==================== matchUsers Lambda Role ====================
resource "aws_iam_role" "lambda_match_users" {
  name               = "${local.name_prefix}-lambda-matchUsers"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "match_users" {
  name = "${local.name_prefix}-matchUsers-policy"
  role = aws_iam_role.lambda_match_users.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          var.posts_table_arn,
          "${var.posts_table_arn}/index/*",
          var.embeddings_table_arn,
          "${var.embeddings_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          var.matches_table_arn,
          var.embeddings_table_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "arn:aws:bedrock:${local.region}::foundation-model/amazon.titan-embed-text-v2:0"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "match_users_logging" {
  role       = aws_iam_role.lambda_match_users.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "match_users_vpc" {
  role       = aws_iam_role.lambda_match_users.name
  policy_arn = aws_iam_policy.lambda_vpc.arn
}

# ==================== joinCommunity Lambda Role ====================
resource "aws_iam_role" "lambda_join_community" {
  name               = "${local.name_prefix}-lambda-joinCommunity"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "join_community" {
  name = "${local.name_prefix}-joinCommunity-policy"
  role = aws_iam_role.lambda_join_community.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          var.communities_table_arn,
          var.users_table_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "join_community_logging" {
  role       = aws_iam_role.lambda_join_community.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "join_community_vpc" {
  role       = aws_iam_role.lambda_join_community.name
  policy_arn = aws_iam_policy.lambda_vpc.arn
}

# ==================== sendMessage Lambda Role ====================
resource "aws_iam_role" "lambda_send_message" {
  name               = "${local.name_prefix}-lambda-sendMessage"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "send_message" {
  name = "${local.name_prefix}-sendMessage-policy"
  role = aws_iam_role.lambda_send_message.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = var.messages_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query"
        ]
        Resource = [
          var.connections_table_arn,
          "${var.connections_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "execute-api:ManageConnections"
        ]
        Resource = "arn:aws:execute-api:${local.region}:${local.account_id}:*/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "send_message_logging" {
  role       = aws_iam_role.lambda_send_message.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "send_message_vpc" {
  role       = aws_iam_role.lambda_send_message.name
  policy_arn = aws_iam_policy.lambda_vpc.arn
}

# ==================== getMessages Lambda Role ====================
resource "aws_iam_role" "lambda_get_messages" {
  name               = "${local.name_prefix}-lambda-getMessages"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "get_messages" {
  name = "${local.name_prefix}-getMessages-policy"
  role = aws_iam_role.lambda_get_messages.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query"
        ]
        Resource = [
          var.messages_table_arn,
          "${var.messages_table_arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "get_messages_logging" {
  role       = aws_iam_role.lambda_get_messages.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "get_messages_vpc" {
  role       = aws_iam_role.lambda_get_messages.name
  policy_arn = aws_iam_policy.lambda_vpc.arn
}

# ==================== discoverCommunities Lambda Role ====================
resource "aws_iam_role" "lambda_discover_communities" {
  name               = "${local.name_prefix}-lambda-discoverCommunities"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "discover_communities" {
  name = "${local.name_prefix}-discoverCommunities-policy"
  role = aws_iam_role.lambda_discover_communities.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [
          var.communities_table_arn,
          "${var.communities_table_arn}/index/*",
          var.posts_table_arn,
          "${var.posts_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query"
        ]
        Resource = [
          var.embeddings_table_arn,
          "${var.embeddings_table_arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "discover_communities_logging" {
  role       = aws_iam_role.lambda_discover_communities.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "discover_communities_vpc" {
  role       = aws_iam_role.lambda_discover_communities.name
  policy_arn = aws_iam_policy.lambda_vpc.arn
}

# ==================== insightsAggregator Lambda Role ====================
resource "aws_iam_role" "lambda_insights_aggregator" {
  name               = "${local.name_prefix}-lambda-insightsAggregator"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "insights_aggregator" {
  name = "${local.name_prefix}-insightsAggregator-policy"
  role = aws_iam_role.lambda_insights_aggregator.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [
          var.posts_table_arn,
          "${var.posts_table_arn}/index/*",
          var.messages_table_arn,
          "${var.messages_table_arn}/index/*",
          var.users_table_arn,
          var.communities_table_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${var.logs_bucket_arn}/insights/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "insights_aggregator_logging" {
  role       = aws_iam_role.lambda_insights_aggregator.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "insights_aggregator_vpc" {
  role       = aws_iam_role.lambda_insights_aggregator.name
  policy_arn = aws_iam_policy.lambda_vpc.arn
}

# ==================== sendPushNotification Lambda Role ====================
resource "aws_iam_role" "lambda_send_push_notification" {
  name               = "${local.name_prefix}-lambda-sendPushNotification"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "send_push_notification" {
  name = "${local.name_prefix}-sendPushNotification-policy"
  role = aws_iam_role.lambda_send_push_notification.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = [
          var.users_table_arn,
          "${var.users_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "sns:CreatePlatformEndpoint",
          "sns:GetEndpointAttributes"
        ]
        Resource = "arn:aws:sns:${local.region}:${local.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:${local.region}:${local.account_id}:parameter/mindconnect/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "send_push_notification_logging" {
  role       = aws_iam_role.lambda_send_push_notification.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "send_push_notification_vpc" {
  role       = aws_iam_role.lambda_send_push_notification.name
  policy_arn = aws_iam_policy.lambda_vpc.arn
}

# ==================== WebSocket Connect/Disconnect Lambda Role ====================
resource "aws_iam_role" "lambda_websocket_handler" {
  name               = "${local.name_prefix}-lambda-websocketHandler"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "websocket_handler" {
  name = "${local.name_prefix}-websocketHandler-policy"
  role = aws_iam_role.lambda_websocket_handler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = [
          var.connections_table_arn,
          "${var.connections_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "execute-api:ManageConnections"
        ]
        Resource = "arn:aws:execute-api:${local.region}:${local.account_id}:*/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "websocket_handler_logging" {
  role       = aws_iam_role.lambda_websocket_handler.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "websocket_handler_vpc" {
  role       = aws_iam_role.lambda_websocket_handler.name
  policy_arn = aws_iam_policy.lambda_vpc.arn
}

# ==================== Presigned URL Generator Lambda Role ====================
resource "aws_iam_role" "lambda_presigned_url" {
  name               = "${local.name_prefix}-lambda-presignedUrl"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "presigned_url" {
  name = "${local.name_prefix}-presignedUrl-policy"
  role = aws_iam_role.lambda_presigned_url.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${var.media_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "presigned_url_logging" {
  role       = aws_iam_role.lambda_presigned_url.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "presigned_url_vpc" {
  role       = aws_iam_role.lambda_presigned_url.name
  policy_arn = aws_iam_policy.lambda_vpc.arn
}

# ==================== ECS Task Role ====================
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${local.name_prefix}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = [
          var.connections_table_arn,
          "${var.connections_table_arn}/index/*",
          var.messages_table_arn,
          "${var.messages_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ]
        Resource = var.messages_stream_arn
      }
    ]
  })
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name               = "${local.name_prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_extra" {
  name = "${local.name_prefix}-ecs-execution-extra"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:${local.region}:${local.account_id}:parameter/mindconnect/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/ecs/${local.name_prefix}-*:*"
      }
    ]
  })
}

# --- Outputs ---
output "lambda_create_post_role_arn" {
  value = aws_iam_role.lambda_create_post.arn
}

output "lambda_classify_risk_role_arn" {
  value = aws_iam_role.lambda_classify_risk.arn
}

output "lambda_match_users_role_arn" {
  value = aws_iam_role.lambda_match_users.arn
}

output "lambda_join_community_role_arn" {
  value = aws_iam_role.lambda_join_community.arn
}

output "lambda_send_message_role_arn" {
  value = aws_iam_role.lambda_send_message.arn
}

output "lambda_get_messages_role_arn" {
  value = aws_iam_role.lambda_get_messages.arn
}

output "lambda_discover_communities_role_arn" {
  value = aws_iam_role.lambda_discover_communities.arn
}

output "lambda_insights_aggregator_role_arn" {
  value = aws_iam_role.lambda_insights_aggregator.arn
}

output "lambda_send_push_notification_role_arn" {
  value = aws_iam_role.lambda_send_push_notification.arn
}

output "lambda_websocket_handler_role_arn" {
  value = aws_iam_role.lambda_websocket_handler.arn
}

output "lambda_presigned_url_role_arn" {
  value = aws_iam_role.lambda_presigned_url.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution_role.arn
}
