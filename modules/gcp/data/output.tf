output "this" {
  value = {
    billing_account        = data.google_billing_account.this
    client_openid_userinfo = data.google_client_openid_userinfo.this
    google_compute_image   = data.google_compute_image.this
    google_compute_zones   = data.google_compute_zones.this
    project                = data.google_projects.this.projects[0]
  }
}