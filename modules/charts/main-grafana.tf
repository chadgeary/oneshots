# resource "helm_release" "this-init-grafana" {
#   chart            = "${path.module}/init"
#   name             = "grafana-init"
#   namespace        = "kube-system"
#   values = [yamlencode({
#     host = "grafana.${var.install.name}.internal"
#     dataplane-mode = "ambient"
#     namespace = "grafana"
#     service = "grafana"
#     port = 80
#   })]
# }

# resource "helm_release" "this-grafana" {
#   chart            = "https://github.com/grafana/helm-charts/releases/download/grafana-8.4.8/grafana-8.4.8.tgz"
#   name             = "grafana"
#   namespace        = "grafana"
#   values = [yamlencode({
#       tolerations = [{
#         effect = "NoSchedule"
#         key = "node-role.kubernetes.io/control-plane"
#         operator = "Exists"
#       }]
#   })]
#   depends_on = [ helm_release.this-init-grafana ]
# }
