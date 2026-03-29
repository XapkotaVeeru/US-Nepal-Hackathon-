# ===========================================================
# Root Outputs - Flutter Integration Values
# ===========================================================

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

# --- Region ---
output "aws_region" {
  description = "AWS region used"
  value       = var.aws_region
}
