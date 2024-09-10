resource "helm_release" "this-istio-base" {
  chart            = "base"
  create_namespace = true
  name             = "istio-base"
  namespace        = "istio-system"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  version          = "1.23.1"
}

resource "helm_release" "this-istio-cni" {
  chart            = "cni"
  create_namespace = true
  name             = "istio-cni"
  namespace        = "istio-system"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  version          = "1.23.1"
  values = [yamlencode({
    cni = {
      cniBinDir  = "/var/lib/rancher/k3s/data/current/bin/"
      cniConfDir = "/var/lib/rancher/k3s/agent/etc/cni/net.d"
    }
    profile = "ambient"
  })]
  depends_on = [
    helm_release.this-aws-ccm,
    helm_release.this-istio-base,
  ]
}

resource "helm_release" "this-istio-istiod" {
  chart            = "istiod"
  create_namespace = true
  name             = "istio-istiod"
  namespace        = "istio-system"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  version          = "1.23.1"
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
          cpu    = "250m"
          memory = "200Mi"
        }
        requests = {
          cpu    = "10m"
          memory = "10Mi"
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
  chart            = "ztunnel"
  create_namespace = true
  name             = "istio-ztunnel"
  namespace        = "istio-system"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  version          = "1.23.1"
  values = [yamlencode({
    resources = {
      limits = {
        cpu    = "1"
        memory = "200Mi"
      }
      requests = {
        cpu    = "20m"
        memory = "50Mi"
      }
    }
  })]
  depends_on = [helm_release.this-istio-istiod]
}

resource "helm_release" "this-istio-gateway" {
  chart            = "gateway"
  create_namespace = true
  name             = "istio-gateway"
  namespace        = "istio-system"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  version          = "1.23.1"
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
        cpu    = "10m"
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

resource "helm_release" "this-istio-certificate" {
  chart     = "${path.module}/certificate"
  name      = "istio-cert"
  namespace = "istio-system"
  values = [yamlencode({
    dnsName = "*.${var.install.name}.duckdns.org"
    name    = var.install.name
  })]
  depends_on = [
    helm_release.this-cert-manager-webhook-duckdns,
    helm_release.this-istio-istiod,
  ]
}
