# eks-retail-platform

An end-to-end, production-shaped EKS project built to be **interview-ready** for
DevOps-on-AWS roles. The workload is the AWS **retail-store-sample-app** (a real
polyglot microservices app), deployed onto EKS with the current (2026) best-practice
stack: managed node group + **self-managed Karpenter**, **EKS Pod Identity**,
Helm, **ArgoCD** (GitOps), **GitHub Actions + OIDC**, ALB Ingress, ExternalDNS,
ACM, External Secrets, and a lean Prometheus/Grafana observability layer.

## Core design decisions (the "why", for interviews)

| Area | Choice | Why not the alternative |
|---|---|---|
| Compute | Managed node group (system) **+ self-managed Karpenter** (apps) | Auto Mode hides NodePools/EC2NodeClass/consolidation — the exact things interviewers probe. We run Karpenter ourselves, then spin up Auto Mode briefly to contrast. |
| Identity | **EKS Pod Identity** (default) | Recommended over IRSA in 2026: no OIDC provider, simpler trust policies. We still wire IRSA once (Fargate/Windows still need it; no IRSA deprecation). |
| State | S3 backend, **native lockfile** (TF ≥ 1.10) | DynamoDB lock table no longer required. |
| Lifecycle | **Build-and-destroy each session** | Persistent vs ephemeral layer split → cluster is cattle, git is truth, rebuild in ~20 min. |
| Networking | Single NAT gateway | Cheapest for a dev/learning loop; prod would use one-per-AZ for HA (noted in code). |

## Layout

```
bootstrap/   PERSISTENT — apply once, leave running (~$1/mo). NEVER destroy.
  00-state-backend/  S3 state bucket (local state, chicken-and-egg)
  10-ecr/            ECR repos for app images (survive cluster rebuilds)
  20-dns-certs/      Route53 zone lookup + wildcard ACM cert (validate once)
platform/    EPHEMERAL — `make up` / `make down` each session   [Phase 1+]
gitops/      ArgoCD app-of-apps                                  [Phase 2+]
ci/          GitHub Actions (OIDC -> ECR)                        [Phase 6]
```

Layers talk to each other through `terraform_remote_state` data sources, so the
ephemeral platform layer reads the bucket name, ECR URLs, cert ARN and zone ID
from the bootstrap layer.

## Roadmap

- **Phase 0 — Bootstrap** *(this scaffold)*: state backend, ECR, DNS+ACM.
- **Phase 1 — Network + cluster**: 3-AZ VPC (1 NAT), EKS, system node group, core
  addons, EKS access entries.
- **Phase 2 — Platform**: Karpenter, ALB controller, ExternalDNS, External Secrets,
  ArgoCD bootstrap.
- **Phase 3 — Workload v1**: retail app via Helm/ArgoCD, in-cluster StatefulSets (EBS).
- **Phase 4 — Workload v2**: RDS / DynamoDB / ElastiCache / SQS + per-service Pod Identity.
- **Phase 5 — Scaling/resilience**: HPA, Karpenter consolidation, spot + PDBs, upgrades.
- **Phase 6 — CI/CD**: GitHub Actions OIDC -> ECR -> ArgoCD sync.
- **Phase 7 — Observability**: kube-prometheus-stack + Fluent Bit -> CloudWatch.
- **Phase 8 — Teardown + interview drills**.

## Prerequisites

- Terraform ≥ 1.10, AWS CLI v2, configured credentials (`aws sts get-caller-identity`).
- Region defaults to **eu-central-1** (Frankfurt). Change in the `region` variables if needed.
- A registered Route53 domain with an existing hosted zone (default: `patriciu.click`).

## Run Phase 0

The S3 bucket name in `backend.hcl` and `00-state-backend` must be **globally unique**.
The default is `patriciu-eks-retail-tfstate` — change it in both places if it's taken.

```bash
# 1. Create the state bucket first (local state)
make bootstrap-state

# 2. Then the layers that store state in that bucket
make bootstrap-ecr
make bootstrap-dns

# ...or all three in order:
make bootstrap
```

Check it worked:

```bash
cd bootstrap/20-dns-certs && terraform output   # acm_certificate_arn, route53_zone_id
aws ecr describe-repositories --query 'repositories[].repositoryName'
```

The ACM validation step waits for DNS to propagate and the cert to be ISSUED — it
can take a few minutes on the first run. After that, every cluster rebuild reuses it.
