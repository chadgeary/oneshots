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
  source = "../../modules/k3s"
  aws    = module.aws.this
  nat    = module.nat.this
  vpc    = module.vpc.this
}
