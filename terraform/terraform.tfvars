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

# ECS Configuration
ecs_cpu           = 512
ecs_memory        = 1024
ecs_desired_count = 2

# DynamoDB
dynamodb_billing_mode = "PAY_PER_REQUEST"

# S3
s3_force_destroy = false
