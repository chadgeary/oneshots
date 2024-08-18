data "archive_file" "this-scaledown" {
  type        = "zip"
  source_dir  = "${path.module}/scaledown"
  output_path = "${path.module}/lambda_scaledown.zip"
}

resource "aws_cloudwatch_log_group" "this-scaledown" {
  name              = "/aws/lambda/${var.aws.default_tags.tags["Name"]}-scaledown"
  retention_in_days = 90
  tags = {
    Name = "/aws/lambda/${var.aws.default_tags.tags["Name"]}-scaledown"
  }
}

resource "aws_iam_role" "this-scaledown" {
  assume_role_policy = data.aws_iam_policy_document.this-lambda-assume.json
  description        = "${var.aws.default_tags.tags["Name"]}-scaledown"
  name               = "${var.aws.default_tags.tags["Name"]}-scaledown"
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-scaledown"
    policy = data.aws_iam_policy_document.this-scaledown.json
  }
}

resource "aws_lambda_function" "this-scaledown" {
  filename         = data.archive_file.this-scaledown.output_path
  source_code_hash = data.archive_file.this-scaledown.output_base64sha256
  function_name    = "${var.aws.default_tags.tags["Name"]}-scaledown"
  role             = aws_iam_role.this-scaledown.arn
  memory_size      = 256
  handler          = "lambda_scaledown.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  depends_on       = [aws_cloudwatch_log_group.this-scaledown]
}

resource "aws_sns_topic_subscription" "this-scaledown" {
  topic_arn = aws_sns_topic.this-controlplane.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.this-scaledown.arn
}

resource "aws_lambda_permission" "this-scaledown" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this-scaledown.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this-controlplane.arn
  statement_id  = "AllowExecutionFromSNS"
}
