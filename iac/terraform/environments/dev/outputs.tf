output "vpc_id" {
  value = module.network.vpc_id
}

output "eks_cluster_name" {
  value = module.compute.cluster_name
}

output "db_endpoint" {
  value = module.data.db_endpoint
}
