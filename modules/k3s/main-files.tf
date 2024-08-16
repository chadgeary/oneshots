data "archive_file" "this-files" {
  type        = "zip"
  source_file = "${path.module}/lambda_files.py"
  output_path = "${path.module}/lambda_files.zip"
}

resource "aws_s3_bucket" "this" {
  bucket        = "${var.aws.default_tags.tags["Name"]}-k3s"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this-s3.json
}

resource "aws_cloudwatch_log_group" "this-files" {
  name              = "/aws/lambda/${var.aws.default_tags.tags["Name"]}-files"
  retention_in_days = 90
  tags = {
    Name = "/aws/lambda/${var.aws.default_tags.tags["Name"]}-files"
  }
}

resource "aws_iam_role" "this-files" {
  assume_role_policy = data.aws_iam_policy_document.this-files-assume.json
  description        = "${var.aws.default_tags.tags["Name"]}-files"
  name               = "${var.aws.default_tags.tags["Name"]}-files"
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-files"
    policy = data.aws_iam_policy_document.this-files.json
  }
}

resource "aws_lambda_function" "this-files" {
  filename         = data.archive_file.this-files.output_path
  source_code_hash = data.archive_file.this-files.output_base64sha256
  function_name    = "${var.aws.default_tags.tags["Name"]}-files"
  role             = aws_iam_role.this-files.arn
  memory_size      = 256
  handler          = "lambda_files.lambda_handler"
  runtime          = "python3.11"
  timeout          = 900
  depends_on       = [aws_cloudwatch_log_group.this-files, aws_s3_bucket_policy.this]
}

# tflint-ignore: terraform_unused_declarations
data "aws_lambda_invocation" "this-files" {
  for_each      = local.files
  function_name = aws_lambda_function.this-files.function_name
  input         = <<EOF
{
 "bucket": "${aws_s3_bucket.this.bucket}",
 "prefix": "${each.value.prefix}",
 "url": "${each.value.url}"
}
EOF
}