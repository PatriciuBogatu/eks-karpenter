# =============================================================================
# eks-retail-platform — Makefile
#
# Persistent (bootstrap): create once, leave running (~$1/mo). Never `destroy`.
# Ephemeral  (platform):  `make up` at session start, `make down` at session end.
# =============================================================================

BACKEND := $(abspath backend.hcl)
TF      := terraform

# ---- helpers ----------------------------------------------------------------
# init-remote <dir>  -> init a layer against the shared S3 backend
define tf_apply_remote
	cd $(1) && $(TF) init -reconfigure -backend-config=$(BACKEND) && $(TF) apply -auto-approve
endef

.PHONY: help
help:
	@echo "Bootstrap (persistent — run once):"
	@echo "  make bootstrap         Create state bucket, ECR repos, DNS+ACM (in order)"
	@echo "  make bootstrap-state   Just the S3 state backend (LOCAL state)"
	@echo "  make bootstrap-ecr     Just the ECR repos"
	@echo "  make bootstrap-dns     Just the hosted-zone lookup + wildcard ACM cert"
	@echo ""
	@echo "Platform (ephemeral — each session):  [added in Phase 1]"
	@echo "  make up                Stand up VPC + EKS + addons"
	@echo "  make down              Tear it all back down to ~\$$1/mo"

# ---- bootstrap (persistent) -------------------------------------------------
.PHONY: bootstrap bootstrap-state bootstrap-ecr bootstrap-dns
bootstrap: bootstrap-state bootstrap-ecr bootstrap-dns
	@echo ">> Bootstrap complete. Outputs cached in each layer's state."

bootstrap-state:
	cd bootstrap/00-state-backend && $(TF) init && $(TF) apply -auto-approve

bootstrap-ecr:
	$(call tf_apply_remote,bootstrap/10-ecr)

bootstrap-dns:
	$(call tf_apply_remote,bootstrap/20-dns-certs)

# ---- platform (ephemeral) — implemented in Phase 1 --------------------------
.PHONY: up down
up:
	@echo "Phase 1 not scaffolded yet — VPC + EKS layers land next."

down:
	@echo "Phase 1 not scaffolded yet. 'make down' will: delete k8s LB/Ingress"
	@echo "resources FIRST (so they don't orphan ALBs/ENIs and block the VPC"
	@echo "destroy), then terraform destroy the platform layers in reverse order."
