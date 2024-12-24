resource "helm_release" "this-istio-namespace" {
  chart     = "${path.module}/namespace"
  name      = "istio-namespace"
  namespace = "kube-system"
  values = [yamlencode({
    namespace = "istio-system"
  })]
}

resource "helm_release" "this-istio-base" {
  chart      = "base"
  name       = "istio-base"
  namespace  = "istio-system"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = "1.24.2"
  depends_on = [
    helm_release.this-istio-namespace,
  ]
}

resource "helm_release" "this-istio-cni" {
  chart      = "cni"
  name       = "istio-cni"
  namespace  = "istio-system"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = "1.24.2"
  values = [yamlencode({
    cni = var.install.provider.k8s == "k3s" ? {
      cniBinDir  = "/var/lib/rancher/k3s/data/current/bin/"
      cniConfDir = "/var/lib/rancher/k3s/agent/etc/cni/net.d"
    } : {}
    profile = "ambient"
  })]
  depends_on = [
    helm_release.this-istio-base,
  ]
}

resource "helm_release" "this-istio-istiod" {
  chart      = "istiod"
  name       = "istio-istiod"
  namespace  = "istio-system"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = "1.24.1"
  values = [yamlencode({
    global = {
      defaultPodDisruptionBudget = {
        enabled = false
      }
    }
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
  chart      = "ztunnel"
  name       = "istio-ztunnel"
  namespace  = "istio-system"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = "1.24.1"
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
  chart      = "gateway"
  name       = "istio-gateway"
  namespace  = "istio-system"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = "1.24.1"
  values = [yamlencode({
    autoscaling = {
      enabled = false
    }
    kind = "DaemonSet"
    resources = {
      limits = {
        cpu    = "1"
        memory = "256Mi"
      }
      requests = {
        cpu    = "10m"
        memory = "32Mi"
      }
    }
    service = {
      externalTrafficPolicy = "Local"
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
    })
  ]
  depends_on = [helm_release.this-istio-ztunnel]
}

resource "helm_release" "this-istio-certificate" {
  chart     = "${path.module}/certificate"
  name      = "istio-cert"
  namespace = "istio-system"
  values = [yamlencode({
    domain = {
      domainprovider = var.install.domain.domainprovider
      domainname     = var.install.domain.domainname
      token          = var.install.domain.token
    }
    name = var.install.name
  })]
  depends_on = [
    helm_release.this-cert-manager,
    helm_release.this-istio-istiod,
  ]
}

resource "helm_release" "this-dnsupdate-duckdns" {
  for_each  = var.install.domain.domainprovider == "duckdns" ? { "duckdns" : true } : {}
  chart     = "${path.module}/dnsupdate"
  name      = "dnsupdate"
  namespace = "cert-manager"
  values = [yamlencode({
    name      = var.install.name
    public_ip = var.nat.eip.public_ip
  })]
  depends_on = [helm_release.this-istio-certificate]
}