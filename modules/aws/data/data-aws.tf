data "aws_availability_zones" "this" {
  state = "available"
}
data "aws_caller_identity" "this" {}
data "aws_default_tags" "this" {}
data "aws_partition" "this" {}
data "aws_region" "this" {}
data "aws_iam_session_context" "this" {
  arn = data.aws_caller_identity.this.arn
}