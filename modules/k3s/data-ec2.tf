data "aws_ec2_instance_type" "this-controlplane" {
  for_each      = toset(var.install.k3s["controlplane"].instance_types)
  instance_type = each.key
}

data "aws_ec2_instance_type" "this-worker" {
  for_each      = toset(var.install.k3s["worker"].instance_types)
  instance_type = each.key
}
