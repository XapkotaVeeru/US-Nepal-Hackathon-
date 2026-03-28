# ===========================================================
# DynamoDB Module
# ===========================================================

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}

locals {
  table_prefix = "${var.project_name}-${var.environment}"
}

# --- Users Table ---
resource "aws_dynamodb_table" "users" {
  name         = "${local.table_prefix}-users"
  billing_mode = var.billing_mode
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "cognitoIdentityId"
    type = "S"
  }

  global_secondary_index {
    name            = "CognitoIdentityIndex"
    hash_key        = "cognitoIdentityId"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${local.table_prefix}-users"
  }
}

# --- Posts Table ---
resource "aws_dynamodb_table" "posts" {
  name             = "${local.table_prefix}-posts"
  billing_mode     = var.billing_mode
  hash_key         = "postId"
  range_key        = "createdAt"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "postId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  attribute {
    name = "communityId"
    type = "S"
  }

  attribute {
    name = "riskLevel"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  global_secondary_index {
    name            = "CommunityPostsIndex"
    hash_key        = "communityId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "UserPostsIndex"
    hash_key        = "userId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "RiskLevelIndex"
    hash_key        = "riskLevel"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Name = "${local.table_prefix}-posts"
  }
}

# --- Messages Table ---
resource "aws_dynamodb_table" "messages" {
  name             = "${local.table_prefix}-messages"
  billing_mode     = var.billing_mode
  hash_key         = "communityId"
  range_key        = "messageId"
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  attribute {
    name = "communityId"
    type = "S"
  }

  attribute {
    name = "messageId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  local_secondary_index {
    name            = "MessagesByTimeIndex"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Name = "${local.table_prefix}-messages"
  }
}

# --- Communities Table ---
resource "aws_dynamodb_table" "communities" {
  name         = "${local.table_prefix}-communities"
  billing_mode = var.billing_mode
  hash_key     = "communityId"

  attribute {
    name = "communityId"
    type = "S"
  }

  attribute {
    name = "category"
    type = "S"
  }

  attribute {
    name = "memberCount"
    type = "N"
  }

  global_secondary_index {
    name            = "CategoryIndex"
    hash_key        = "category"
    range_key       = "memberCount"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${local.table_prefix}-communities"
  }
}

# --- Matches Table ---
resource "aws_dynamodb_table" "matches" {
  name         = "${local.table_prefix}-matches"
  billing_mode = var.billing_mode
  hash_key     = "userId"
  range_key    = "matchedUserId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "matchedUserId"
    type = "S"
  }

  attribute {
    name = "similarityScore"
    type = "N"
  }

  local_secondary_index {
    name            = "SimilarityScoreIndex"
    range_key       = "similarityScore"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Name = "${local.table_prefix}-matches"
  }
}

# --- Embeddings Table ---
resource "aws_dynamodb_table" "embeddings" {
  name         = "${local.table_prefix}-embeddings"
  billing_mode = var.billing_mode
  hash_key     = "entityId"
  range_key    = "entityType"

  attribute {
    name = "entityId"
    type = "S"
  }

  attribute {
    name = "entityType"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${local.table_prefix}-embeddings"
  }
}

# --- WebSocket Connections Table ---
resource "aws_dynamodb_table" "connections" {
  name         = "${local.table_prefix}-connections"
  billing_mode = var.billing_mode
  hash_key     = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }

  attribute {
    name = "communityId"
    type = "S"
  }

  global_secondary_index {
    name            = "CommunityConnectionsIndex"
    hash_key        = "communityId"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "${local.table_prefix}-connections"
  }
}

# --- Outputs ---
output "users_table_name" {
  value = aws_dynamodb_table.users.name
}

output "users_table_arn" {
  value = aws_dynamodb_table.users.arn
}

output "posts_table_name" {
  value = aws_dynamodb_table.posts.name
}

output "posts_table_arn" {
  value = aws_dynamodb_table.posts.arn
}

output "posts_stream_arn" {
  value = aws_dynamodb_table.posts.stream_arn
}

output "messages_table_name" {
  value = aws_dynamodb_table.messages.name
}

output "messages_table_arn" {
  value = aws_dynamodb_table.messages.arn
}

output "messages_stream_arn" {
  value = aws_dynamodb_table.messages.stream_arn
}

output "communities_table_name" {
  value = aws_dynamodb_table.communities.name
}

output "communities_table_arn" {
  value = aws_dynamodb_table.communities.arn
}

output "matches_table_name" {
  value = aws_dynamodb_table.matches.name
}

output "matches_table_arn" {
  value = aws_dynamodb_table.matches.arn
}

output "embeddings_table_name" {
  value = aws_dynamodb_table.embeddings.name
}

output "embeddings_table_arn" {
  value = aws_dynamodb_table.embeddings.arn
}

output "connections_table_name" {
  value = aws_dynamodb_table.connections.name
}

output "connections_table_arn" {
  value = aws_dynamodb_table.connections.arn
}

output "all_table_arns" {
  value = [
    aws_dynamodb_table.users.arn,
    aws_dynamodb_table.posts.arn,
    aws_dynamodb_table.messages.arn,
    aws_dynamodb_table.communities.arn,
    aws_dynamodb_table.matches.arn,
    aws_dynamodb_table.embeddings.arn,
    aws_dynamodb_table.connections.arn,
  ]
}
