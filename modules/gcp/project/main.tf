resource "google_project" "this" {
  billing_account = data.google_billing_account.this.id
  name            = var.install.name
  project_id      = var.install.name
  deletion_policy = "DELETE"
}

resource "google_project_service" "this" {
  for_each                   = toset(local.services)
  disable_dependent_services = true
  project                    = google_project.this.project_id
  service                    = each.key
}
