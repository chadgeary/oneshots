# resource "helm_release" "this-fluent-bit-namespace" {
#   chart     = "${path.module}/namespace"
#   name      = "fluent-bit-namespace"
#   namespace = "kube-system"
#   values = [yamlencode({
#     dataplane-mode = "ambient"
#     namespace      = "fluent-bit"
#   })]
#   depends_on = [helm_release.this-istio-ztunnel]
# }

# resource "helm_release" "this-fluent-bit" {
#   chart      = "fluent-bit"
#   name       = "fluent-bit"
#   namespace  = "fluent-bit"
#   repository = "https://fluent.github.io/helm-charts"
#   version    = "0.47.10"
#   values = [yamlencode({
#     config = {
#       inputs  = <<EOF
# [INPUT]
#     Name tail
#     Path /var/log/containers/*.log
#     multiline.parser docker, cri
#     Tag kube.*
#     Mem_Buf_Limit 5MB
#     Skip_Long_Lines On

# [INPUT]
#     Name systemd
#     Tag host.*
#     Systemd_Filter _SYSTEMD_UNIT=amazon-ssm-agent.service
#     Systemd_Filter _SYSTEMD_UNIT=k3s-agent.service
#     Systemd_Filter _SYSTEMD_UNIT=k3s.service
#     Read_From_Tail On
# EOF
#       outputs = <<EOF
# [OUTPUT]
#     Name loki
#     Match kube.*
#     Host loki.logging.svc.cluster.local
#     labels              tag=kube, namespace=$kubernetes['namespace_name']
#     structured_metadata pod=$kubernetes['pod_name']

# [OUTPUT]
#     Name loki
#     Match systemd.*
#     labels              tag=host
#     Host loki.logging.svc.cluster.local
# EOF
#     }
#     tolerations = [{
#       operator = "Exists"
#     }]
#   })]
#   depends_on = [
#     helm_release.this-fluent-bit-namespace,
#   ]
# }
