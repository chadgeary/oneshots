data "google_billing_account" "this" {
  display_name = length(var.install.billing) > 0 ? var.install.billing : null
  open         = true
}

data "google_client_openid_userinfo" "this" {}

data "google_projects" "this" {
  filter = "name:${var.install.name}"
}

data "google_compute_zones" "this" {
  project = var.install.name
  status  = "UP"
}

data "google_compute_image" "this" {
  for_each = {
    debian = {
      family  = "debian-12"
      project = "debian-cloud"
    }
  }
  family  = each.value.family
  project = each.value.project
}