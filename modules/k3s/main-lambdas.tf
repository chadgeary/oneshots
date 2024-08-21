locals {
  lambdas = toset([
    "files",
    "watch",
    "gracefulshutdown",
  ])
}

data "archive_file" "this-lambdas" {
  for_each    = local.lambdas
  type        = "zip"
  source_dir  = "${path.module}/lambdas/${each.key}"
  output_path = "${path.module}/lambda_${each.key}.zip"
}

resource "aws_cloudwatch_log_group" "this-lambdas" {
  for_each          = local.lambdas
  name              = "/aws/lambda/${var.aws.default_tags.tags["Name"]}-${each.key}"
  retention_in_days = 90
  tags = {
    Name = "/aws/lambda/${var.aws.default_tags.tags["Name"]}-${each.key}"
  }
}

resource "aws_iam_role" "this-lambdas" {
  for_each           = local.lambdas
  assume_role_policy = data.aws_iam_policy_document.this-assume["lambda"].json
  description        = "${var.aws.default_tags.tags["Name"]}-${each.key}"
  name               = "${var.aws.default_tags.tags["Name"]}-${each.key}"
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-${each.key}"
    policy = data.aws_iam_policy_document.this-lambdas[each.key].json
  }
}

resource "aws_lambda_function" "this-lambdas" {
  for_each         = local.lambdas
  filename         = data.archive_file.this-lambdas[each.key].output_path
  source_code_hash = data.archive_file.this-lambdas[each.key].output_base64sha256
  function_name    = "${var.aws.default_tags.tags["Name"]}-${each.key}"
  role             = aws_iam_role.this-lambdas[each.key].arn
  memory_size      = 256
  handler          = "lambda_${each.key}.lambda_handler"
  runtime          = "python3.11"
  timeout          = 600
  depends_on       = [aws_cloudwatch_log_group.this-lambdas]
}
