# ===========================================================
# Root Outputs - Flutter Integration Values
# ===========================================================

# --- API Gateway Endpoints (for Flutter) ---
output "api_gateway_http_url" {
  description = "HTTP API base URL for Flutter dio/http package"
  value       = module.api_gateway.http_api_endpoint
}

output "api_gateway_websocket_url" {
  description = "WebSocket URL for Flutter web_socket_channel"
  value       = module.api_gateway.websocket_api_endpoint
}

# --- Cognito (for Flutter anonymous auth) ---
output "cognito_identity_pool_id" {
  description = "Cognito Identity Pool ID for Flutter"
  value       = module.cognito.identity_pool_id
}

# --- S3 ---
output "media_bucket_name" {
  description = "S3 bucket for media uploads"
  value       = module.s3.media_bucket_name
}

# --- ECS ---
output "ecr_websocket_repository_url" {
  description = "ECR repo URL for WebSocket Docker image"
  value       = module.ecs.ecr_websocket_url
}

output "ecr_embedding_repository_url" {
  description = "ECR repo URL for embedding service Docker image"
  value       = module.ecs.ecr_embedding_url
}

output "ecs_alb_dns_name" {
  description = "ALB DNS name for ECS services"
  value       = module.ecs.alb_dns_name
}

# --- VPC ---
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

# --- DynamoDB ---
output "dynamodb_tables" {
  description = "All DynamoDB table names"
  value = {
    users       = module.dynamodb.users_table_name
    posts       = module.dynamodb.posts_table_name
    messages    = module.dynamodb.messages_table_name
    communities = module.dynamodb.communities_table_name
    matches     = module.dynamodb.matches_table_name
    embeddings  = module.dynamodb.embeddings_table_name
    connections = module.dynamodb.connections_table_name
  }
}

# --- SNS ---
output "sns_crisis_alerts_topic_arn" {
  description = "SNS topic ARN for crisis alerts"
  value       = module.sns_fcm.crisis_alerts_topic_arn
}

# --- CloudWatch ---
output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.cloudwatch.dashboard_name
}

# --- Region ---
output "aws_region" {
  description = "AWS region used"
  value       = var.aws_region
}
