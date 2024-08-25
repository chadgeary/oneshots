resource "helm_release" "this-cert-manager" {
  chart            = "https://charts.jetstack.io/charts/cert-manager-v1.15.3.tgz"
  create_namespace = true
  name             = "cert-manager"
  namespace        = "cert-manager"
  values = [yamlencode({
    crds = {
      enabled = true
    }
    controller = {
      replicaCount = 1
      tolerations = [{
        effect   = "NoSchedule"
        key      = "node-role.kubernetes.io/control-plane"
        operator = "Exists"
      }]
    }
  })]
}

# resource "helm_release" "this-cert-manager-webhook-duckdns" {
#   chart            = "https://charts.jetstack.io/charts/cert-manager-v1.15.3.tgz"
#   create_namespace = true
#   name             = "cert-manager"
#   namespace        = "cert-manager"
#   values = [yamlencode({
#     crds = {
#       enabled = true
#     }
#     controller = {
#       replicaCount = 1
#       tolerations = [{
#         effect   = "NoSchedule"
#         key      = "node-role.kubernetes.io/control-plane"
#         operator = "Exists"
#       }]
#     }
#   })]
# }
