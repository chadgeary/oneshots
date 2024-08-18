output "this" {
  value = {
    amis               = data.aws_ami.this
    availability_zones = data.aws_availability_zones.this
    caller_identity    = data.aws_caller_identity.this
    default_tags       = data.aws_default_tags.this
    partition       = data.aws_partition.this
    region          = data.aws_region.this
    session_context = data.aws_iam_session_context.this
  }
}