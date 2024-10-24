resource "helm_release" "this-cert-manager" {
  chart            = "cert-manager"
  create_namespace = true
  name             = "cert-manager"
  namespace        = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = "v1.16.1"
  values = [yamlencode({
    crds = {
      enabled = true
    }
    replicaCount = 1
  })]
}

resource "helm_release" "this-cert-manager-webhook-duckdns" {
  for_each         = var.install.domain.domainprovider == "duckdns" ? { "duckdns" : true } : {}
  chart            = "cert-manager-webhook-duckdns"
  create_namespace = true
  name             = "cert-manager-webhook-duckdns"
  namespace        = "cert-manager"
  repository       = "https://chadgeary.github.io/cert-manager-webhook-duckdns"
  version          = "1.0.1"
  values = [yamlencode({
    groupName = "acme.webhook.duckdns.org"
    secret = {
      existingSecret     = true
      existingSecretName = "${var.install.name}-duckdns"
    }
  })]
  depends_on = [helm_release.this-cert-manager]
}
