# gitops/ — ArgoCD-managed application layer

Terraform bootstrapped ArgoCD (platform layer). This folder is what ArgoCD
*manages*: the application layer, via the **app-of-apps** pattern.

```
gitops/
├── bootstrap/root-app.yaml      # the ONE Application you apply by hand
├── apps/retail-store.yaml       # child app (discovered by root); add more here
└── values/retail-store-v1.yaml  # Phase 3 in-cluster-datastore overrides
```

## Flow

1. Terraform installs ArgoCD.
2. You apply `bootstrap/root-app.yaml` once. It watches `gitops/apps/`.
3. ArgoCD finds `apps/retail-store.yaml` and deploys the retail store.
4. Adding any future app = commit a new Application YAML to `apps/`. ArgoCD
   syncs it automatically. Git is the source of truth; the cluster reconciles.

## Before you apply: set your repo URL

`root-app.yaml` and `apps/retail-store.yaml` both have `REPO_URL` placeholders.
ArgoCD pulls manifests/values from Git, so this folder must live in a repo
ArgoCD can read. Push the project to your own GitHub repo (public is simplest
for now; Phase 6 adds private-repo creds + CI), then replace both `REPO_URL`s
with `https://github.com/<you>/eks-retail-platform.git`.

## Apply the root app

```bash
kubectl apply -f gitops/bootstrap/root-app.yaml
# watch it sync:
kubectl -n argocd get applications
argocd app get retail-store        # if you've logged into the CLI
```

## No-Git fast path (try it before pushing to GitHub)

If you just want to see the app run *now* without pushing to Git, install the
chart directly with Helm using the same values file — same result, no GitOps:

```bash
helm install retail-store \
  oci://public.ecr.aws/aws-containers/retail-store-sample-chart \
  --version 1.6.1 \
  --namespace retail-store --create-namespace \
  -f gitops/values/retail-store-v1.yaml
```

Then switch to the GitOps path once your repo is pushed — that contrast (manual
`helm install` vs declarative ArgoCD sync) is itself a good thing to be able to
articulate.

## Verifying the in-cluster datastores (the Phase 3 learning goal)

```bash
kubectl -n retail-store get pods
kubectl -n retail-store get statefulsets       # mysql, postgresql, rabbitmq, redis, dynamodb
kubectl -n retail-store get pvc                 # EBS-backed PersistentVolumeClaims (gp3)
kubectl -n retail-store get svc                 # note the headless svc for each StatefulSet
```
