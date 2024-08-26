resource "helm_release" "this-cert-manager" {
  chart            = "https://charts.jetstack.io/charts/cert-manager-v1.15.3.tgz"
  create_namespace = true
  name             = "cert-manager"
  namespace        = "cert-manager"
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
  chart            = "https://github.com/chadgeary/cert-manager-webhook-duckdns/releases/download/cert-manager-webhook-duckdns-1.0.0/cert-manager-webhook-duckdns-1.0.0.tgz"
  create_namespace = true
  name             = "cert-manager-webhook-duckdns"
  namespace        = "cert-manager"
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
      token = var.install.duckdnstoken
    }
  })]
  depends_on = [helm_release.this-cert-manager]
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
