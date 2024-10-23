locals {
  ami            = length(data.aws_ec2_instance_type_offerings.this-arm64.instance_types) > 0 ? var.aws.amis["minimal-arm64"] : var.aws.amis["minimal-amd64"]
  instance_types = length(data.aws_ec2_instance_type_offerings.this-arm64.instance_types) > 0 ? sort(data.aws_ec2_instance_type_offerings.this-arm64.instance_types) : sort(data.aws_ec2_instance_type_offerings.this-amd64.instance_types)
  private        = cidrsubnet(var.install.network.cidr, 1, 1)
  public         = cidrsubnet(var.install.network.cidr, 1, 0)
}
