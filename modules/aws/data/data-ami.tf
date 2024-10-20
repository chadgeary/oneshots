locals {
  amis = {
    arm64         = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
    amd64         = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
    minimal-arm64 = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-arm64"
    minimal-amd64 = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64"
  }
}

data "aws_ssm_parameter" "this" {
  for_each = local.amis
  name     = each.value
}

data "aws_ami" "this" {
  for_each    = data.aws_ssm_parameter.this
  most_recent = true

  filter {
    name = "image-id"
    values = [
      nonsensitive(data.aws_ssm_parameter.this[each.key].value)
    ]
  }
}
