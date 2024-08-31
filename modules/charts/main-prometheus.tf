resource "helm_release" "this-prometheus-namespace" {
  chart     = "${path.module}/namespace"
  name      = "prometheus-namespace"
  namespace = "kube-system"
  values = [yamlencode({
    dataplane-mode = "ambient"
    namespace      = "prometheus"
  })]
  depends_on = [helm_release.this-istio-ztunnel]
}

resource "helm_release" "this-prometheus" {
  chart     = "https://github.com/prometheus-community/helm-charts/releases/download/kube-prometheus-stack-62.3.0/kube-prometheus-stack-62.3.0.tgz"
  name      = "prometheus"
  namespace = "prometheus"
  values = [yamlencode({
    alertmanager = {
      enabled = false
    }
    grafana = {
      enabled = false
    }
    kubeEtcd = {
      enabled = false
    }
    kubeScheduler = {
      enabled = false
    }
    kubeStateMetrics = {
      enabled = false
    }
    kubeProxy = {
      enabled = false
    }
    prometheus = {
      prometheusSpec = {
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "gp3"
              resources = {
                requests = {
                  storage = "3Gi"
                }
              }
            }
          }
        }
      }
    }

  })]
  depends_on = [
    helm_release.this-prometheus-namespace,
    helm_release.this-ebs,
  ]
}
