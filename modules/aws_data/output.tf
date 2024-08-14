output "this" {
  value = {
    amis               = data.aws_ami.this
    availability_zones = data.aws_availability_zones.this
    caller_identity    = data.aws_caller_identity.this
    default_tags       = data.aws_default_tags.this
    nat_instance_types = {
      amd64 = sort(data.aws_ec2_instance_type_offerings.this_amd64.instance_types)
      arm64 = sort(data.aws_ec2_instance_type_offerings.this_arm64.instance_types)
    }
    partition = data.aws_partition.this
    region    = data.aws_region.this
  }
}