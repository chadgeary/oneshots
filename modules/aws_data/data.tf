data "aws_availability_zones" "this" {
  state = "available"
}
data "aws_caller_identity" "this" {}
data "aws_default_tags" "this" {}
data "aws_partition" "this" {}
data "aws_region" "this" {}

# amis
data "aws_ssm_parameter" "this" {
    for_each = toset(["x86_64", "arm64"])
    name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-${each.key}"
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
