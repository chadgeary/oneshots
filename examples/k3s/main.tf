module "aws" {
  source = "../../modules/aws"
}

module "vpc" {
  source  = "../../modules/vpc"
  aws     = module.aws.this
  install = var.install
}

module "nat" {
  source = "../../modules/nat"
  aws    = module.aws.this
  vpc    = module.vpc.this
}

module "k3s" {
  source     = "../../modules/k3s"
  aws        = module.aws.this
  install    = var.install
  nat        = module.nat.this
  vpc        = module.vpc.this
  depends_on = [module.nat]
}

resource "local_sensitive_file" "this" {
  content         = module.k3s.this.files["config"].body
  file_permission = "0600"
  filename        = "${path.root}/config"
}

module "charts" {
  source     = "../../modules/charts"
  aws        = module.aws.this
  cluster    = module.k3s.this
  install    = var.install
  nat        = module.nat.this
  depends_on = [module.nat]
}
