variable "project" {
  type    = string
  default = "eks-retail"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

# One ECR repo per microservice in the retail-store sample app. The CI pipeline
# (Phase 6) builds and pushes images here; until then the cluster can pull the
# upstream public images. These repos PERSIST across cluster rebuilds so you're
# never rebuilding images just because you ran `make down`.
variable "services" {
  description = "Microservices that get an ECR repository."
  type        = list(string)
  default     = ["ui", "catalog", "cart", "checkout", "orders"]
}
