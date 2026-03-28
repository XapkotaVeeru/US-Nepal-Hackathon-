# ===========================================================
# API Gateway Module - HTTP API + WebSocket API
# ===========================================================

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cors_allowed_origins" {
  type    = list(string)
  default = ["*"]
}

# Lambda Invoke ARNs
variable "create_post_invoke_arn" {
  type = string
}

variable "join_community_invoke_arn" {
  type = string
}

variable "send_message_invoke_arn" {
  type = string
}

variable "get_messages_invoke_arn" {
  type = string
}

variable "discover_communities_invoke_arn" {
  type = string
}

variable "insights_aggregator_invoke_arn" {
  type = string
}

variable "send_push_notification_invoke_arn" {
  type = string
}

variable "match_users_invoke_arn" {
  type = string
}

variable "presigned_url_invoke_arn" {
  type = string
}

# Lambda ARNs
variable "create_post_arn" {
  type = string
}

variable "join_community_arn" {
  type = string
}

variable "send_message_arn" {
  type = string
}

variable "get_messages_arn" {
  type = string
}

variable "discover_communities_arn" {
  type = string
}

variable "insights_aggregator_arn" {
  type = string
}

variable "send_push_notification_arn" {
  type = string
}

variable "match_users_arn" {
  type = string
}

variable "presigned_url_arn" {
  type = string
}

# WebSocket Lambda ARNs and Invoke ARNs
variable "ws_connect_arn" {
  type = string
}

variable "ws_connect_invoke_arn" {
  type = string
}

variable "ws_disconnect_arn" {
  type = string
}

variable "ws_disconnect_invoke_arn" {
  type = string
}

variable "ws_default_arn" {
  type = string
}

variable "ws_default_invoke_arn" {
  type = string
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ===========================================================
# HTTP API (for REST endpoints from Flutter)
# ===========================================================

resource "aws_apigatewayv2_api" "http" {
  name          = "${local.name_prefix}-http-api"
  protocol_type = "HTTP"
  description   = "HTTP API for MindConnect Flutter app"

  cors_configuration {
    allow_headers  = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
    allow_methods  = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_origins  = var.cors_allowed_origins
    expose_headers = ["*"]
    max_age        = 3600
  }

  tags = {
    Name = "${local.name_prefix}-http-api"
  }
}

resource "aws_apigatewayv2_stage" "http" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.http_api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      errorMessage   = "$context.error.message"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }

  tags = {
    Name = "${local.name_prefix}-http-stage"
  }

  depends_on = [
    aws_api_gateway_account.main
  ]
}

resource "aws_cloudwatch_log_group" "http_api" {
  name              = "/aws/apigateway/${local.name_prefix}-http-api"
  retention_in_days = 30

  tags = {
    Name = "${local.name_prefix}-http-api-logs"
  }
}

# --- HTTP API Lambda Integrations ---

resource "aws_apigatewayv2_integration" "create_post" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.create_post_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "join_community" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.join_community_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "send_message" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.send_message_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "get_messages" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.get_messages_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "discover_communities" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.discover_communities_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "insights" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.insights_aggregator_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "push_notification" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.send_push_notification_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "match_users" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.match_users_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "presigned_url" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.presigned_url_invoke_arn
  payload_format_version = "2.0"
}

# --- HTTP API Routes ---

resource "aws_apigatewayv2_route" "create_post" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /posts"
  target    = "integrations/${aws_apigatewayv2_integration.create_post.id}"
}

resource "aws_apigatewayv2_route" "join_community" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /communities/{communityId}/join"
  target    = "integrations/${aws_apigatewayv2_integration.join_community.id}"
}

resource "aws_apigatewayv2_route" "send_message" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /messages"
  target    = "integrations/${aws_apigatewayv2_integration.send_message.id}"
}

resource "aws_apigatewayv2_route" "get_messages" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /communities/{communityId}/messages"
  target    = "integrations/${aws_apigatewayv2_integration.get_messages.id}"
}

resource "aws_apigatewayv2_route" "discover_communities" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /communities/discover"
  target    = "integrations/${aws_apigatewayv2_integration.discover_communities.id}"
}

resource "aws_apigatewayv2_route" "get_insights" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /insights"
  target    = "integrations/${aws_apigatewayv2_integration.insights.id}"
}

resource "aws_apigatewayv2_route" "register_token" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /notifications/register"
  target    = "integrations/${aws_apigatewayv2_integration.push_notification.id}"
}

resource "aws_apigatewayv2_route" "send_notification" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /notifications/send"
  target    = "integrations/${aws_apigatewayv2_integration.push_notification.id}"
}

resource "aws_apigatewayv2_route" "get_matches" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /matches"
  target    = "integrations/${aws_apigatewayv2_integration.match_users.id}"
}

resource "aws_apigatewayv2_route" "presigned_url" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /media/upload-url"
  target    = "integrations/${aws_apigatewayv2_integration.presigned_url.id}"
}

# --- Lambda Permissions for HTTP API ---

resource "aws_lambda_permission" "http_create_post" {
  statement_id  = "AllowHTTPAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.create_post_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_lambda_permission" "http_join_community" {
  statement_id  = "AllowHTTPAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.join_community_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_lambda_permission" "http_send_message" {
  statement_id  = "AllowHTTPAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.send_message_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_lambda_permission" "http_get_messages" {
  statement_id  = "AllowHTTPAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.get_messages_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_lambda_permission" "http_discover_communities" {
  statement_id  = "AllowHTTPAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.discover_communities_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_lambda_permission" "http_insights" {
  statement_id  = "AllowHTTPAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.insights_aggregator_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_lambda_permission" "http_push_notification" {
  statement_id  = "AllowHTTPAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.send_push_notification_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_lambda_permission" "http_match_users" {
  statement_id  = "AllowHTTPAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.match_users_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_lambda_permission" "http_presigned_url" {
  statement_id  = "AllowHTTPAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.presigned_url_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

# ===========================================================
# API Gateway Account-Level CloudWatch Logging Role
# ===========================================================

resource "aws_iam_role" "apigw_cloudwatch" {
  name = "${local.name_prefix}-apigw-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apigw_cloudwatch" {
  role       = aws_iam_role.apigw_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch.arn

  depends_on = [
    aws_iam_role_policy_attachment.apigw_cloudwatch
  ]
}

# ===========================================================
# WebSocket API (for real-time chat from Flutter)
# ===========================================================

resource "aws_apigatewayv2_api" "websocket" {
  name                       = "${local.name_prefix}-websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  description                = "WebSocket API for MindConnect real-time chat"

  tags = {
    Name = "${local.name_prefix}-websocket-api"
  }
}

resource "aws_apigatewayv2_stage" "websocket" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.websocket_api.arn
    format = jsonencode({
      requestId    = "$context.requestId"
      ip           = "$context.identity.sourceIp"
      requestTime  = "$context.requestTime"
      routeKey     = "$context.routeKey"
      status       = "$context.status"
      connectionId = "$context.connectionId"
      eventType    = "$context.eventType"
    })
  }

  default_route_settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 100
  }

  tags = {
    Name = "${local.name_prefix}-websocket-stage"
  }

  depends_on = [
    aws_api_gateway_account.main
  ]
}

resource "aws_cloudwatch_log_group" "websocket_api" {
  name              = "/aws/apigateway/${local.name_prefix}-websocket-api"
  retention_in_days = 30

  tags = {
    Name = "${local.name_prefix}-websocket-api-logs"
  }
}

# --- WebSocket Integrations ---

resource "aws_apigatewayv2_integration" "ws_connect" {
  api_id                    = aws_apigatewayv2_api.websocket.id
  integration_type          = "AWS_PROXY"
  integration_uri           = var.ws_connect_invoke_arn
  content_handling_strategy = "CONVERT_TO_TEXT"
}

resource "aws_apigatewayv2_integration" "ws_disconnect" {
  api_id                    = aws_apigatewayv2_api.websocket.id
  integration_type          = "AWS_PROXY"
  integration_uri           = var.ws_disconnect_invoke_arn
  content_handling_strategy = "CONVERT_TO_TEXT"
}

resource "aws_apigatewayv2_integration" "ws_default" {
  api_id                    = aws_apigatewayv2_api.websocket.id
  integration_type          = "AWS_PROXY"
  integration_uri           = var.ws_default_invoke_arn
  content_handling_strategy = "CONVERT_TO_TEXT"
}

# --- WebSocket Routes ---

resource "aws_apigatewayv2_route" "ws_connect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_connect.id}"
}

resource "aws_apigatewayv2_route" "ws_disconnect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_disconnect.id}"
}

resource "aws_apigatewayv2_route" "ws_default" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.ws_default.id}"
}

resource "aws_apigatewayv2_route" "ws_send_message" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "sendMessage"
  target    = "integrations/${aws_apigatewayv2_integration.ws_default.id}"
}

resource "aws_apigatewayv2_route" "ws_join_community" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "joinCommunity"
  target    = "integrations/${aws_apigatewayv2_integration.ws_default.id}"
}

# --- WebSocket Lambda Permissions ---

resource "aws_lambda_permission" "ws_connect" {
  statement_id  = "AllowWSAPIConnect"
  action        = "lambda:InvokeFunction"
  function_name = var.ws_connect_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "ws_disconnect" {
  statement_id  = "AllowWSAPIDisconnect"
  action        = "lambda:InvokeFunction"
  function_name = var.ws_disconnect_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "ws_default" {
  statement_id  = "AllowWSAPIDefault"
  action        = "lambda:InvokeFunction"
  function_name = var.ws_default_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

# --- Outputs ---
output "http_api_id" {
  value = aws_apigatewayv2_api.http.id
}

output "http_api_endpoint" {
  value = "${aws_apigatewayv2_api.http.api_endpoint}/${var.environment}"
}

output "http_api_execution_arn" {
  value = aws_apigatewayv2_api.http.execution_arn
}

output "websocket_api_id" {
  value = aws_apigatewayv2_api.websocket.id
}

output "websocket_api_endpoint" {
  value = "${aws_apigatewayv2_api.websocket.api_endpoint}/${var.environment}"
}

output "websocket_api_execution_arn" {
  value = aws_apigatewayv2_api.websocket.execution_arn
}
