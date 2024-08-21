# tflint-ignore: terraform_unused_declarations
data "aws_lambda_invocation" "this-files" {
  for_each      = local.files
  function_name = aws_lambda_function.this-lambdas["files"].function_name
  input         = <<EOF
{
 "bucket": "${aws_s3_bucket.this.bucket}",
 "prefix": "${each.value.prefix}",
 "url": "${each.value.url}"
}
EOF
}

# tflint-ignore: terraform_unused_declarations
data "aws_lambda_invocation" "this-watch" {
  function_name = aws_lambda_function.this-lambdas["watch"].function_name
  input         = ""
}
