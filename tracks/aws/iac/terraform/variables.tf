variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

# Proveer via: TF_VAR_db_password, terraform.tfvars (gitignored), o Secrets Manager.
variable "db_password" {
  description = "Database master password — provide via TF_VAR_db_password or tfvars (gitignored)"
  type        = string
  sensitive   = true
  # ELIMINADO: default = "hardcoded-password"
}

variable "tags" {
  description = "A map of common tags"
  type        = map(string)
  default = {
    Project    = "novaledger"
    ManagedBy  = "terraform"
    Track      = "aws"
    Compliance = "pci-dss"
  }
}