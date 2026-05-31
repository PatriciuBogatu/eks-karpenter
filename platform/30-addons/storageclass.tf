# The EBS CSI driver was installed as a managed addon in the cluster layer, but
# EKS's DEFAULT StorageClass is gp2. gp3 is cheaper, faster, and the modern
# default — so we create a gp3 class and mark it default. The retail app's
# StatefulSets (Phase 3) and any PVC without an explicit class will use this.
#
# WHY HERE (addons layer, Terraform via the kubernetes provider): it's a
# cluster-wide platform primitive, like the controllers — not application config.
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer" # bind the PV in the same AZ the pod lands in
  allow_volume_expansion = true
  reclaim_policy         = "Delete"
  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

# Remove gp2's default flag so we don't have two default StorageClasses (which
# makes PVCs without a className ambiguous). This patches the EKS-shipped class.
resource "kubernetes_annotations" "gp2_not_default" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }
  force = true

  depends_on = [kubernetes_storage_class_v1.gp3]
}
