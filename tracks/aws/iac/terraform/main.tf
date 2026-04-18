# NovaLedger — AWS Track Terraform

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remoto para colaboración y locking
  # Descomentar y ajustar bucket/tabla antes de usar
  # backend "s3" {
  #   bucket         = "novaledger-terraform-state"
  #   key            = "tracks/aws/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "novaledger-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.60.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "novaledger-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.60.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false


  tags = {
    Name = "novaledger-${var.environment}-private-a"
    Tier = "private"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.60.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = {
    Name = "novaledger-${var.environment}-private-b"
    Tier = "private"
  }
}

# -----------------------------------------------------------------------------
# Security Group — Base de Datos
# -----------------------------------------------------------------------------
resource "aws_security_group" "db" {
  name        = "novaledger-${var.environment}-db"
  description = "Security group for RDS PostgreSQL — restricted to VPC CIDR"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL from VPC only"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "novaledger-${var.environment}-db-sg"
  }
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "db" {
  name       = "novaledger-${var.environment}-db-subnet"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]


  tags = {
    Name = "novaledger-${var.environment}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier     = "novaledger-${var.environment}-postgres"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 100 # Autoscaling de storage
  db_name  = "payments"
  username = "novaledger_admin"

  password = var.db_password
  publicly_accessible     = false

  storage_encrypted       = true

  skip_final_snapshot     = false

  final_snapshot_identifier = "novaledger-${var.environment}-final-snapshot"
  backup_retention_period = 7

  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  # Alta disponibilidad
  multi_az = true # Failover automático, RTO < 2 min
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
  # Monitoring
  monitoring_interval          = 60
  performance_insights_enabled = true

  tags = {
    Name        = "novaledger-${var.environment}-postgres"
    Environment = var.environment
  }
}
