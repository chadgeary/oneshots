module "aws_data" {
  source = "../../modules/aws_data"
}

module "vpc" {
  source   = "../../modules/vpc"
  aws_data = module.aws_data.this
  install  = var.install
}

module "vpc_data" {
  source     = "../../modules/vpc_data"
  aws_data   = module.aws_data.this
  depends_on = [module.vpc]
}

module "nat" {
  source   = "../../modules/nat"
  aws_data = module.aws_data.this
  vpc_data = module.vpc_data.this
  install  = var.install
}
