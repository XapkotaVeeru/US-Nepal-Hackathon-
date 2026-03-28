# ===========================================================
# Terraform Remote State Backend (Optional)
# ===========================================================
# Uncomment and configure after creating the S3 bucket and DynamoDB table
# for state locking. Run `terraform init` after enabling.
#
# terraform {
#   backend "s3" {
#     bucket         = "mindconnect-terraform-state-CHANGE_ME"
#     key            = "mental-health-app/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }
