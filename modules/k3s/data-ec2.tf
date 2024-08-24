data "aws_ec2_instance_type_offerings" "this-arm64" {
  filter {
    name = "instance-type"
    values = [
      "t4g.small",
    ]
  }
}

data "aws_ec2_instance_type_offerings" "this-amd64" {
  filter {
    name = "instance-type"
    values = [
      "t3.small",
      "t3a.small",
    ]
  }
}
