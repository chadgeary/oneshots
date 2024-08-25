resource "helm_release" "this-istio-base" {
  chart            = "https://istio-release.storage.googleapis.com/charts/base-1.23.0.tgz"
  create_namespace = true
  name             = "istio-base"
  namespace        = "istio-system"
}

resource "helm_release" "this-istio-cni" {
  chart            = "https://istio-release.storage.googleapis.com/charts/cni-1.23.0.tgz"
  create_namespace = true
  name             = "istio-cni"
  namespace        = "istio-system"
  values = [yamlencode({
    cni = {
      cniBinDir  = "/var/lib/rancher/k3s/data/current/bin/"
      cniConfDir = "/var/lib/rancher/k3s/agent/etc/cni/net.d"
    }
    profile = "ambient"
  })]
  depends_on = [helm_release.this-istio-base]
}

resource "helm_release" "this-istio-istiod" {
  chart            = "https://istio-release.storage.googleapis.com/charts/istiod-1.23.0.tgz"
  create_namespace = true
  name             = "istio-istiod"
  namespace        = "istio-system"
  values = [yamlencode({
    pilot = {
      autoscaleEnabled = false
      cni = {
        enabled = true
      }
      env = {
        PILOT_ENABLE_AMBIENT = "true"
      }
      replicaCount = 1
      resources = {
        limits = {
          cpu    = "1"
          memory = "200Mi"
        }
        requests = {
          cpu    = "10m"
          memory = "50Mi"
        }
      }
      tolerations = [{
        effect   = "NoSchedule"
        key      = "node-role.kubernetes.io/control-plane"
        operator = "Exists"
      }]
    }
    })
  ]
  depends_on = [helm_release.this-istio-cni]
}

resource "helm_release" "this-istio-ztunnel" {
  chart            = "https://istio-release.storage.googleapis.com/charts/ztunnel-1.23.0.tgz"
  create_namespace = true
  name             = "istio-ztunnel"
  namespace        = "istio-system"
  values = [yamlencode({
    resources = {
      limits = {
        cpu    = "1"
        memory = "200Mi"
      }
      requests = {
        cpu    = "50m"
        memory = "50Mi"
      }
    }
  })]
  depends_on = [helm_release.this-istio-istiod]
}

resource "helm_release" "this-istio-gateway" {
  chart            = "https://istio-release.storage.googleapis.com/charts/gateway-1.23.0.tgz"
  create_namespace = true
  name             = "istio-gateway"
  namespace        = "istio-system"
  values = [yamlencode({
    autoscaling = {
      enabled = false
    }
    nodeSelector = {
      "node-role.kubernetes.io/control-plane" = "true"
    }
    replicaCount = 1
    resources = {
      limits = {
        cpu    = "1"
        memory = "200Mi"
      }
      requests = {
        cpu    = "50m"
        memory = "50Mi"
      }
    }
    service = {
      type = "NodePort"
      ports = [
        {
          name = "status-port"
          port = 15021
        },
        {
          name     = "http2"
          port     = 80
          nodePort = 31080
        },
        {
          name     = "https"
          port     = 443
          nodePort = 31443
        },
      ]
    }
    tolerations = [{
      effect   = "NoSchedule"
      key      = "node-role.kubernetes.io/control-plane"
      operator = "Exists"
    }]
    })
  ]
  depends_on = [helm_release.this-istio-ztunnel]
}
