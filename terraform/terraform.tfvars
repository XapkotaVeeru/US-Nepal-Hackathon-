# ===========================================================
# Terraform Variable Values
# ===========================================================
# IMPORTANT: Replace placeholder values before running terraform apply.
# Never commit secrets to version control.

aws_region         = "us-east-1"
project_name       = "mindconnect"
environment        = "dev"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Lambda Configuration
lambda_runtime = "python3.12"
lambda_timeout = 30
lambda_memory  = 256

# ECS Configuration
ecs_cpu           = 512
ecs_memory        = 1024
ecs_desired_count = 2

# DynamoDB
dynamodb_billing_mode = "PAY_PER_REQUEST"

# FCM - Store actual key in SSM Parameter Store, NOT here
fcm_server_key_parameter_name = "/mindconnect/fcm/server-key"

# S3
s3_force_destroy = false

# Observability
enable_cloudwatch_alarms = true
log_retention_days       = 30

# CORS - Restrict in production
cors_allowed_origins = ["*"]

# EventBridge Schedules
eventbridge_insights_schedule = "cron(0 2 * * ? *)"
eventbridge_matching_schedule = "rate(6 hours)"
eventbridge_cleanup_schedule  = "rate(24 hours)"
