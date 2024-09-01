resource "helm_release" "this-grafana-namespace" {
  chart     = "${path.module}/namespace"
  name      = "grafana-namespace"
  namespace = "kube-system"
  values = [yamlencode({
    dataplane-mode = "ambient"
    namespace      = "grafana"
  })]
  depends_on = [helm_release.this-istio-ztunnel]
}

resource "helm_release" "this-grafana-gateway" {
  chart     = "${path.module}/gateway"
  name      = "grafana-gateway"
  namespace = "grafana"
  values = [yamlencode({
    host    = "grafana.${var.install.name}.duckdns.org"
    name    = var.install.name
    port    = 80
    service = "grafana"
  })]
  depends_on = [helm_release.this-grafana-namespace]
}

resource "helm_release" "this-grafana" {
  chart      = "grafana"
  name       = "grafana"
  namespace  = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  version    = "8.4.8"
  values = [yamlencode({
    datasources = {
      "datasources.yaml" = {
        apiVersion = 1
        datasources = [
          {
            name   = "Prometheus"
            type   = "prometheus"
            url    = "http://prometheus-kube-prometheus-prometheus.prometheus.svc.cluster.local:9090"
            access = "proxy"
          },
          {
            name   = "Loki"
            type   = "loki"
            url    = "http://loki.logging.svc.cluster.local:3100"
            access = "proxy"
            jsonData = {
              timeout  = 60
              maxLines = 1000
            }
          },
        ]
      }
    }
    persistence = {
      enabled          = true
      size             = "2Gi"
      storageClassName = "gp3"
    }
  })]
  depends_on = [
    helm_release.this-ebs,
    helm_release.this-grafana-gateway,
  ]
}
