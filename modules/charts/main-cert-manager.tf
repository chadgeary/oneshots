resource "helm_release" "this-cert-manager" {
  chart            = "cert-manager"
  create_namespace = true
  name             = "cert-manager"
  namespace        = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = "v1.16.0"
  values = [yamlencode({
    crds = {
      enabled = true
    }
    controller = {
      replicaCount = 1
      tolerations = [{
        effect   = "NoSchedule"
        key      = "node-role.kubernetes.io/control-plane"
        operator = "Exists"
      }]
    }
  })]
}

resource "helm_release" "this-cert-manager-webhook-duckdns" {
  chart            = "cert-manager-webhook-duckdns"
  create_namespace = true
  name             = "cert-manager-webhook-duckdns"
  namespace        = "cert-manager"
  repository       = "https://chadgeary.github.io/cert-manager-webhook-duckdns"
  version          = "1.0.0"
  values = [yamlencode({
    groupName = "acme.webhook.duckdns.org"
    clusterIssuer = {
      email = "cert-manager-webhook@${var.install.name}.cluster.home.arpa"
      production = {
        create = true
      }
      staging = {
        create = true
      }
    }
    duckdns = {
      token = var.install.charts.duckdnstoken
    }
  })]
  depends_on = [
    helm_release.this-aws-ccm,
    helm_release.this-cert-manager,
  ]
}

resource "helm_release" "this-dnsupdate" {
  chart     = "${path.module}/dnsupdate"
  name      = "dnsupdate"
  namespace = "cert-manager"
  values = [yamlencode({
    name      = var.install.name
    public_ip = var.nat.eip[keys(var.nat.eip)[0]].public_ip
  })]
  depends_on = [helm_release.this-cert-manager-webhook-duckdns]
}
