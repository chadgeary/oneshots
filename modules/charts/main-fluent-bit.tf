resource "helm_release" "this-fluent-bit-namespace" {
  chart     = "${path.module}/namespace"
  name      = "fluent-bit-namespace"
  namespace = "kube-system"
  values = [yamlencode({
    dataplane-mode = "ambient"
    namespace      = "fluent-bit"
  })]
  depends_on = [helm_release.this-istio-ztunnel]
}

resource "helm_release" "this-fluent-bit" {
  chart     = "https://github.com/fluent/helm-charts/releases/download/fluent-bit-0.47.7/fluent-bit-0.47.7.tgz"
  name      = "fluent-bit"
  namespace = "fluent-bit"
  values = [yamlencode({
    config = {
      inputs  = <<EOF
[INPUT]
    Name tail
    Path /var/log/containers/*.log
    multiline.parser docker, cri
    Tag kube.*
    Mem_Buf_Limit 5MB
    Skip_Long_Lines On

[INPUT]
    Name systemd
    Tag host.*
    Systemd_Filter _SYSTEMD_UNIT=k3s.service
    Read_From_Tail On

[INPUT]
    Name systemd
    Tag host.*
    Systemd_Filter _SYSTEMD_UNIT=k3s-agent.service
    Read_From_Tail On
EOF
      outputs = <<EOF
[OUTPUT]
    Name loki
    Match kube.*
    Host loki.logging.svc.cluster.local
    auto_kubernetes_labels on
EOF
    }
    tolerations = [{
      operator = "Exists"
    }]
  })]
  depends_on = [
    helm_release.this-fluent-bit-namespace,
  ]
}
