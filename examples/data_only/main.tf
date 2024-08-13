module "aws_data" {
  source = "../../modules/aws_data"
}

output "aws_data" {
    value = module.aws_data.this
    sensitive = false
}
