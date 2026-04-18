variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "allowed_cidr" {
  type = string
}

variable "backup_retention" {
  type = number
}

variable "storage_encrypted" {
  type = bool
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "tags" {
  type = map(string)
}
