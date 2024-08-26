data "aws_ec2_instance_type_offerings" "this-controlplane-arm64" {
  filter {
    name = "instance-type"
    values = [
      "t4g.small",
    ]
  }
}

data "aws_ec2_instance_type_offerings" "this-controlplane-amd64" {
  filter {
    name = "instance-type"
    values = [
      "t3.small",
      "t3a.small",
    ]
  }
}

data "aws_ec2_instance_type_offerings" "this-worker-arm64" {
  filter {
    name = "instance-type"
    values = [
      "t4g.medium",
    ]
  }
}

data "aws_ec2_instance_type_offerings" "this-worker-amd64" {
  filter {
    name = "instance-type"
    values = [
      "t3.medium",
      "t3a.medium",
    ]
  }
}
