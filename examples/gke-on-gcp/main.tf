module "project" {
  source  = "../../modules/gcp/project"
  install = var.install
}

module "gcp" {
  source     = "../../modules/gcp/data"
  install    = var.install
  depends_on = [module.project]
}

module "nat" {
  source  = "../../modules/gcp/nat"
  install = var.install
  gcp     = module.gcp.this
}

module "gke" {
  source     = "../../modules/gcp/gke"
  install    = var.install
  gcp        = module.gcp.this
  depends_on = [module.nat]
}

resource "local_sensitive_file" "this" {
  content         = module.gke.this.files["config"]
  file_permission = "0600"
  filename        = "${path.root}/config"
}

module "charts" {
  source     = "../../modules/charts"
  install    = var.install
  nat        = module.nat.this
  depends_on = [module.nat]
}
