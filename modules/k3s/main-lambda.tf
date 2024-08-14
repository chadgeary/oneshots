data "archive_file" "this" {
  type        = "zip"
  source_file = "${path.module}/lambda_files.py"
  output_path = "${path.module}/lambda_files.zip"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.aws.default_tags.tags["Name"]}-files"
  retention_in_days = 90
  tags = {
    Name = "/aws/lambda/${var.aws.default_tags.tags["Name"]}-files"
  }
}

resource "aws_iam_role" "this-files" {
  assume_role_policy = data.aws_iam_policy_document.this-assume.json
  description        = "${var.aws.default_tags.tags["Name"]}-files"
  name               = "${var.aws.default_tags.tags["Name"]}-files"
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-files"
    policy = data.aws_iam_policy_document.this.json
  }
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  function_name    = "${var.aws.default_tags.tags["Name"]}-files"
  role             = aws_iam_role.this-files.arn
  memory_size      = 256
  handler          = "lambda_files.lambda_handler"
  runtime          = "python3.11"
  timeout          = 900
  depends_on       = [aws_cloudwatch_log_group.this]
}

# tflint-ignore: terraform_unused_declarations
data "aws_lambda_invocation" "this" {
  for_each      = local.files
  function_name = aws_lambda_function.this.function_name
  input         = <<EOF
{
 "bucket": "${aws_s3_bucket.this.bucket}",
 "prefix": "${each.value.prefix}",
 "url": "${each.value.url}"
}
EOF
}