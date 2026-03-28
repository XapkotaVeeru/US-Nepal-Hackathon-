# ===========================================================
# Root Main - MindConnect Mental Health Backend
# ===========================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- VPC ---
module "vpc" {
  source             = "./modules/vpc"
  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# --- S3 Buckets ---
module "s3" {
  source        = "./modules/s3"
  project_name  = var.project_name
  environment   = var.environment
  force_destroy = var.s3_force_destroy
}

# --- DynamoDB Tables ---
module "dynamodb" {
  source       = "./modules/dynamodb"
  project_name = var.project_name
  environment  = var.environment
  billing_mode = var.dynamodb_billing_mode
}

# --- IAM Roles ---
module "iam" {
  source                = "./modules/iam"
  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  users_table_arn       = module.dynamodb.users_table_arn
  posts_table_arn       = module.dynamodb.posts_table_arn
  messages_table_arn    = module.dynamodb.messages_table_arn
  communities_table_arn = module.dynamodb.communities_table_arn
  matches_table_arn     = module.dynamodb.matches_table_arn
  embeddings_table_arn  = module.dynamodb.embeddings_table_arn
  connections_table_arn = module.dynamodb.connections_table_arn
  posts_stream_arn      = module.dynamodb.posts_stream_arn
  messages_stream_arn   = module.dynamodb.messages_stream_arn
  media_bucket_arn      = module.s3.media_bucket_arn
  logs_bucket_arn       = module.s3.logs_bucket_arn
}

# --- Bedrock IAM Policies ---
module "bedrock_iam" {
  source       = "./modules/bedrock_iam"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}

# --- SNS / FCM Push Notifications ---
module "sns_fcm" {
  source                        = "./modules/sns_fcm"
  project_name                  = var.project_name
  environment                   = var.environment
  fcm_server_key_parameter_name = var.fcm_server_key_parameter_name
}

# --- Cognito (Anonymous Identity) ---
module "cognito" {
  source       = "./modules/cognito"
  project_name = var.project_name
  environment  = var.environment
}

# --- Lambda Functions ---
module "lambda" {
  source       = "./modules/lambda"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  runtime      = var.lambda_runtime
  timeout      = var.lambda_timeout
  memory_size  = var.lambda_memory

  private_subnet_ids       = module.vpc.private_subnet_ids
  lambda_security_group_id = module.vpc.lambda_security_group_id

  # IAM Role ARNs
  create_post_role_arn            = module.iam.lambda_create_post_role_arn
  classify_risk_role_arn          = module.iam.lambda_classify_risk_role_arn
  match_users_role_arn            = module.iam.lambda_match_users_role_arn
  join_community_role_arn         = module.iam.lambda_join_community_role_arn
  send_message_role_arn           = module.iam.lambda_send_message_role_arn
  get_messages_role_arn           = module.iam.lambda_get_messages_role_arn
  discover_communities_role_arn   = module.iam.lambda_discover_communities_role_arn
  insights_aggregator_role_arn    = module.iam.lambda_insights_aggregator_role_arn
  send_push_notification_role_arn = module.iam.lambda_send_push_notification_role_arn
  websocket_handler_role_arn      = module.iam.lambda_websocket_handler_role_arn
  presigned_url_role_arn          = module.iam.lambda_presigned_url_role_arn

  # DynamoDB Table Names
  users_table_name       = module.dynamodb.users_table_name
  posts_table_name       = module.dynamodb.posts_table_name
  messages_table_name    = module.dynamodb.messages_table_name
  communities_table_name = module.dynamodb.communities_table_name
  matches_table_name     = module.dynamodb.matches_table_name
  embeddings_table_name  = module.dynamodb.embeddings_table_name
  connections_table_name = module.dynamodb.connections_table_name

  # Stream ARNs
  posts_stream_arn    = module.dynamodb.posts_stream_arn
  messages_stream_arn = module.dynamodb.messages_stream_arn

  # Other
  media_bucket_name      = module.s3.media_bucket_name
  crisis_alerts_topic_arn = module.sns_fcm.crisis_alerts_topic_arn
  fcm_parameter_name     = module.sns_fcm.fcm_parameter_name
}

# --- API Gateway ---
module "api_gateway" {
  source               = "./modules/api_gateway"
  project_name         = var.project_name
  environment          = var.environment
  cors_allowed_origins = var.cors_allowed_origins

  # Lambda Invoke ARNs
  create_post_invoke_arn           = module.lambda.create_post_invoke_arn
  join_community_invoke_arn        = module.lambda.join_community_invoke_arn
  send_message_invoke_arn          = module.lambda.send_message_invoke_arn
  get_messages_invoke_arn          = module.lambda.get_messages_invoke_arn
  discover_communities_invoke_arn  = module.lambda.discover_communities_invoke_arn
  insights_aggregator_invoke_arn   = module.lambda.insights_aggregator_invoke_arn
  send_push_notification_invoke_arn = module.lambda.send_push_notification_invoke_arn
  match_users_invoke_arn           = module.lambda.match_users_invoke_arn
  presigned_url_invoke_arn         = module.lambda.presigned_url_invoke_arn

  # Lambda ARNs (for permissions)
  create_post_arn           = module.lambda.create_post_arn
  join_community_arn        = module.lambda.join_community_arn
  send_message_arn          = module.lambda.send_message_arn
  get_messages_arn          = module.lambda.get_messages_arn
  discover_communities_arn  = module.lambda.discover_communities_arn
  insights_aggregator_arn   = module.lambda.insights_aggregator_arn
  send_push_notification_arn = module.lambda.send_push_notification_arn
  match_users_arn           = module.lambda.match_users_arn
  presigned_url_arn         = module.lambda.presigned_url_arn

  # WebSocket Lambda
  ws_connect_arn        = module.lambda.ws_connect_arn
  ws_connect_invoke_arn = module.lambda.ws_connect_invoke_arn
  ws_disconnect_arn        = module.lambda.ws_disconnect_arn
  ws_disconnect_invoke_arn = module.lambda.ws_disconnect_invoke_arn
  ws_default_arn        = module.lambda.ws_default_arn
  ws_default_invoke_arn = module.lambda.ws_default_invoke_arn
}

# --- ECS Fargate ---
module "ecs" {
  source                = "./modules/ecs"
  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  cpu                   = var.ecs_cpu
  memory                = var.ecs_memory
  desired_count         = var.ecs_desired_count
  private_subnet_ids    = module.vpc.private_subnet_ids
  public_subnet_ids     = module.vpc.public_subnet_ids
  ecs_security_group_id = module.vpc.ecs_security_group_id
  alb_security_group_id = module.vpc.alb_security_group_id
  ecs_task_role_arn     = module.iam.ecs_task_role_arn
  ecs_execution_role_arn = module.iam.ecs_execution_role_arn
  connections_table_name = module.dynamodb.connections_table_name
  messages_table_name   = module.dynamodb.messages_table_name
  messages_stream_arn   = module.dynamodb.messages_stream_arn
}

# --- EventBridge Schedules ---
module "eventbridge" {
  source                  = "./modules/eventbridge"
  project_name            = var.project_name
  environment             = var.environment
  insights_schedule       = var.eventbridge_insights_schedule
  matching_schedule       = var.eventbridge_matching_schedule
  cleanup_schedule        = var.eventbridge_cleanup_schedule
  insights_aggregator_arn = module.lambda.insights_aggregator_arn
  match_users_arn         = module.lambda.match_users_arn
}

# --- CloudWatch Observability ---
module "cloudwatch" {
  source                = "./modules/cloudwatch"
  project_name          = var.project_name
  environment           = var.environment
  log_retention_days    = var.log_retention_days
  enable_alarms         = var.enable_cloudwatch_alarms
  lambda_function_names = module.lambda.all_function_names
  ecs_cluster_name      = module.ecs.cluster_name
  ecs_service_name      = module.ecs.websocket_service_name
}
