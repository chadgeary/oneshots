data "aws_s3_object" "this" {
  for_each = toset([
    "config",
    "oidc/.well-known/openid-configuration",
    "oidc/ca.thumbprint",
    "oidc/openid/v1/jwks",
  ])
  bucket = aws_s3_bucket.this.id
  key    = "controlplane/${each.key}"
  depends_on = [
    aws_ssm_association.this-nat,
    data.aws_lambda_invocation.this-watch,
  ]
}
