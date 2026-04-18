variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "novaledger"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.40.0.0/16"
}

variable "db_username" {
  description = "DB master username"
  type        = string
  default     = "novaledger_admin"
}

# Proveer via TF_VAR_db_password o terraform.tfvars (gitignored)
variable "db_password" {
  description = "DB master password"
  type        = string
  sensitive   = true
  # ELIMINADO: default = "changeme123"
}
