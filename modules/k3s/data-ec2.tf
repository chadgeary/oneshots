data "aws_ec2_instance_type_offerings" "this-arm64" {
  filter {
    name = "instance-type"
    values = [
      "t4g.micro",
    ]
  }
}

data "aws_ec2_instance_type_offerings" "this-amd64" {
  filter {
    name = "instance-type"
    values = [
      "t3.micro",
      "t3a.micro",
    ]
  }
}
