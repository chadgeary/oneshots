module "aws" {
  source = "../../../modules/aws/data"
}

module "cloudflare" {
  source = "../../../modules/cloudflare/data"
}

module "ha-one" {
  source     = "../../../modules/aws/ha-one"
  aws        = module.aws.this
  cloudflare = module.cloudflare.this
  install    = var.install
}
