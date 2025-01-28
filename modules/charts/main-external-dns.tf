resource "helm_release" "this-external-dns" {
  for_each         = var.install.domain.domainprovider == "cloudflare" ? { "cloudflare" : true } : {}
  chart            = "external-dns"
  create_namespace = true
  name             = "external-dns"
  namespace        = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  version          = "1.15.1"
  values = [yamlencode({
    provider = {
      name = var.install.domain.domainprovider
    }
    env     = [{ name = "CF_API_TOKEN", value = var.install.domain.token }]
    sources = ["istio-virtualservice"]
  })]
}
