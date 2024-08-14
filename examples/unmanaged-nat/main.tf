module "aws" {
  source = "../../modules/aws"
}

module "vpc" {
  source   = "../../modules/vpc"
  aws_data = module.aws.this
  install  = var.install
}

module "nat" {
  source = "../../modules/nat"
  aws    = module.aws.this
  vpc    = module.vpc.this
}
