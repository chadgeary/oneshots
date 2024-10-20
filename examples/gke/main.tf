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

# module "gke" {
#   source     = "../../modules/gcp/gke"
#   install    = var.install
#   gcp        = module.gcp.this
#   depends_on = [module.nat]
# }
