output "this" {
  value = {
    amis               = data.aws_ami.this
    availability_zones = data.aws_availability_zones.this
    caller_identity    = data.aws_caller_identity.this
    default_tags       = data.aws_default_tags.this
    k3s_instance_types = {
      amd64 = sort(data.aws_ec2_instance_type_offerings.this-k3s-amd64.instance_types)
      arm64 = sort(data.aws_ec2_instance_type_offerings.this-k3s-arm64.instance_types)
    }
    nat_instance_types = {
      amd64 = sort(data.aws_ec2_instance_type_offerings.this-nat-amd64.instance_types)
      arm64 = sort(data.aws_ec2_instance_type_offerings.this-nat-arm64.instance_types)
    }
    partition       = data.aws_partition.this
    region          = data.aws_region.this
    session_context = data.aws_iam_session_context.this
  }
}