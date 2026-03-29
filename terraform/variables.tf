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
