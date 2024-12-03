resource "helm_release" "this-loki-namespace" {
  chart     = "${path.module}/namespace"
  name      = "loki-namespace"
  namespace = "kube-system"
  values = [yamlencode({
    dataplane-mode = "ambient"
    namespace      = "logging"
  })]
  depends_on = [helm_release.this-istio-ztunnel]
}

resource "helm_release" "this-loki" {
  chart      = "loki"
  name       = "loki"
  namespace  = "logging"
  repository = "https://grafana.github.io/helm-charts"
  version    = "6.22.0"
  values = [yamlencode({
    deploymentMode = "SingleBinary"
    loki = {
      auth_enabled = false
      commonConfig = {
        replication_factor = 1
      }
      retention_deletes_enabled = true
      retention_period          = "168h"
      schemaConfig = {
        configs = [{
          from = "2024-01-01"
          index = {
            period = "24h"
            prefix = "index_"
          }
          object_store = "filesystem"
          schema       = "v13"
          store        = "tsdb"
        }]
      }
      storage = {
        type = "filesystem"
      }
    }
    singleBinary = {
      persistence = {
        enabled      = true
        size         = "2Gi"
        storageClass = var.install.provider.storageclass
      }
      replicas = 1
    }
    backend = {
      replicas = 0
    }
    chunksCache = {
      enabled = false
    }
    lokiCanary = {
      enabled = false
    }
    read = {
      replicas = 0
    }
    gateway = {
      enabled = false
    }
    test = {
      enabled = false
    }
    resultsCache = {
      enabled = false
    }
    write = {
      replicas = 0
    }
  })]
  depends_on = [
    helm_release.this-loki-namespace,
  ]
}
