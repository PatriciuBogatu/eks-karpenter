output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "Private subnet IDs — nodes and the control plane ENIs live here."
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs — internet-facing ALBs live here."
  value       = module.vpc.public_subnets
}

output "azs" {
  value = local.azs
}
