# resource "helm_release" "this-grafana-gateway" {
#   chart            = "${path.module}/gateway"
#   name             = "grafana-gateway"
#   namespace        = "kube-system"
#   values = [yamlencode({
#     dataplane-mode = "ambient"
#     host = "grafana.${var.install.name}.duckdns.org"
#     name = var.install.name
#     namespace = "grafana"
#     port = 80
#     service = "grafana"
#   })]
#   depends_on = [ helm_release.this-istio-certificate ]
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
#   depends_on = [ 
#     helm_release.this-ebs,
#     helm_release.this-grafana-gateway,
#   ]
# }
