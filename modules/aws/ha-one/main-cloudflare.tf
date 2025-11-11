locals {
  domain = [for each in var.cloudflare.cloudflare_zones.result : each if each.name == var.install.domain][0]
}

resource "cloudflare_dns_record" "this" {
  zone_id = local.domain.id
  name    = "panel.${local.domain.name}"
  proxied = true
  ttl     = 1
  type    = "A"
  content = aws_eip.this.public_ip
}

resource "cloudflare_zone_setting" "this" {
  zone_id    = local.domain.id
  setting_id = "ssl"
  value      = "full"
}