module "aws" {
  source = "../../modules/aws/aws"
}

module "vpc" {
  source  = "../../modules/aws/vpc"
  aws     = module.aws.this
  install = var.install
}

module "nat" {
  source = "../../modules/aws/nat"
  aws    = module.aws.this
  vpc    = module.vpc.this
}

module "k3s" {
  source     = "../../modules/aws/k3s"
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
  source     = "../../modules/aws/charts"
  aws        = module.aws.this
  cluster    = module.k3s.this
  install    = var.install
  nat        = module.nat.this
  depends_on = [module.nat]
}
