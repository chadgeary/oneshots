provider "google" {
  region = var.install.region
  default_labels = {
    name = var.install.name
  }
}