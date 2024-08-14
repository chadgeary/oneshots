data "aws_ssm_parameter" "this" {
  for_each = toset(["x86_64", "arm64"])
  name     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-${each.key}"
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
