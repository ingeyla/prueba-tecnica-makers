# Environment: dev

locals {
  name = "${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  name     = local.name
  vpc_cidr = var.vpc_cidr
  tags     = local.tags
}

module "compute" {
  source = "../../modules/compute"

  name               = local.name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  tags               = local.tags
}

module "data" {
  source = "../../modules/data"

  name              = local.name
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_subnet_ids
  db_username       = var.db_username
  db_password       = var.db_password
  allowed_cidr      = module.network.vpc_cidr

  backup_retention  = 7

  storage_encrypted = true

  multi_az          = false                     # Dev no necesita Multi-AZ (ahorro de costos)
  tags              = local.tags
}
