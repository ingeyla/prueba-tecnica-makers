# Módulo Data — RDS PostgreSQL

resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "DB security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from allowed CIDR"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.subnet_ids

  tags = var.tags
}

resource "aws_db_instance" "postgres" {
  identifier     = "${var.name}-postgres"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 100 # Autoscaling de storage
  db_name  = "payments"
  username = var.db_username
  password = var.db_password
  publicly_accessible = false

  multi_az            = var.multi_az
  # Backups y recuperación
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name}-final-snapshot"
  backup_retention_period   = var.backup_retention
  backup_window             = "03:00-04:00"
  maintenance_window        = "Mon:04:00-Mon:05:00"
  # Cifrado
  storage_encrypted = var.storage_encrypted
  # Monitoring
  performance_insights_enabled = true
  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  tags = merge(var.tags, {
    DataClass = "confidential"
  })
}
