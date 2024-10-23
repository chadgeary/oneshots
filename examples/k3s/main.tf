module "aws" {
  source = "../../modules/aws/data"
}

module "nat" {
  source  = "../../modules/aws/nat"
  aws     = module.aws.this
  install = var.install
}

module "k3s" {
  source     = "../../modules/aws/k3s"
  aws        = module.aws.this
  install    = var.install
  nat        = module.nat.this
  depends_on = [module.nat]
}

resource "local_sensitive_file" "this" {
  content         = module.k3s.this.files["config"].body
  file_permission = "0600"
  filename        = "${path.root}/config"
}

module "aws_charts" {
  source     = "../../modules/aws/charts"
  aws        = module.aws.this
  cluster    = module.k3s.this
  install    = var.install
  depends_on = [module.nat]
}

module "charts" {
  source     = "../../modules/charts"
  install    = var.install
  nat        = module.nat.this
  depends_on = [module.aws_charts]
}
