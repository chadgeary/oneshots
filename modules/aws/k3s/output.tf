output "this" {
  value = {
    files = data.aws_s3_object.this
    idp   = aws_iam_openid_connect_provider.this
  }
}
