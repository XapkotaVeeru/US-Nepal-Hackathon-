# ===========================================================
# Root Main - MindConnect Mental Health Backend
# ===========================================================

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
module "iam_ecs" {
  source                = "./modules/iam_ecs"
  project_name          = var.project_name
  environment           = var.environment
  connections_table_arn = module.dynamodb.connections_table_arn
  messages_table_arn    = module.dynamodb.messages_table_arn
  messages_stream_arn   = module.dynamodb.messages_stream_arn
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
  ecs_task_role_arn     = module.iam_ecs.ecs_task_role_arn
  ecs_execution_role_arn = module.iam_ecs.ecs_execution_role_arn
  connections_table_name = module.dynamodb.connections_table_name
  messages_table_name   = module.dynamodb.messages_table_name
  messages_stream_arn   = module.dynamodb.messages_stream_arn
}
