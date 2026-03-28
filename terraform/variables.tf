# ===========================================================
# Root Variables
# ===========================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "mindconnect"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "lambda_runtime" {
  description = "Runtime for Lambda functions"
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Default Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory" {
  description = "Default Lambda memory in MB"
  type        = number
  default     = 256
}

variable "ecs_cpu" {
  description = "ECS Fargate task CPU units"
  type        = number
  default     = 512
}

variable "ecs_memory" {
  description = "ECS Fargate task memory in MB"
  type        = number
  default     = 1024
}

variable "ecs_desired_count" {
  description = "Desired count for ECS service"
  type        = number
  default     = 2
}

variable "fcm_server_key_parameter_name" {
  description = "SSM Parameter Store name for FCM server key"
  type        = string
  default     = "/mindconnect/fcm/server-key"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "s3_force_destroy" {
  description = "Allow S3 bucket destruction with objects"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins for API Gateway"
  type        = list(string)
  default     = ["*"]
}

variable "eventbridge_insights_schedule" {
  description = "Cron schedule for daily insights aggregation"
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "eventbridge_matching_schedule" {
  description = "Cron schedule for user matching (every 6 hours)"
  type        = string
  default     = "rate(6 hours)"
}

variable "eventbridge_cleanup_schedule" {
  description = "Cron schedule for cleanup tasks"
  type        = string
  default     = "rate(24 hours)"
}
