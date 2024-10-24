provider "google" {
  region = var.install.region
  default_labels = {
    name = var.install.name
  }
}

provider "helm" {
  kubernetes {
    token                  = module.gcp.this.client_config.access_token
    cluster_ca_certificate = base64decode(module.gke.this.cluster.master_auth[0].cluster_ca_certificate)
    host                   = "https://${module.gke.this.cluster.endpoint}"
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}