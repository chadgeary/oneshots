data "aws_ec2_instance_type_offerings" "this-arm64" {
  filter {
    name = "instance-type"
    values = [
      "t4g.micro",
      "t4g.nano",
      "t4g.small",
    ]
  }
}

data "aws_ec2_instance_type_offerings" "this-amd64" {
  filter {
    name = "instance-type"
    values = [
      "t3.micro",
      "t3.nano",
      "t3.small",
      "t3a.micro",
      "t3a.nano",
      "t3a.small",
    ]
  }
}
