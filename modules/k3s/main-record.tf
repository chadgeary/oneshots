data "archive_file" "this-record" {
  type        = "zip"
  source_file = "${path.module}/lambda_record.py"
  output_path = "${path.module}/lambda_record.zip"
}

resource "aws_cloudwatch_log_group" "this-record" {
  name              = "/aws/lambda/${var.aws.default_tags.tags["Name"]}-record"
  retention_in_days = 90
  tags = {
    Name = "/aws/lambda/${var.aws.default_tags.tags["Name"]}-record"
  }
}

resource "aws_iam_role" "this-record" {
  assume_role_policy = data.aws_iam_policy_document.this-record-assume.json
  description        = "${var.aws.default_tags.tags["Name"]}-record"
  name               = "${var.aws.default_tags.tags["Name"]}-record"
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-record"
    policy = data.aws_iam_policy_document.this-record.json
  }
}

resource "aws_lambda_function" "this-record" {
  filename         = data.archive_file.this-record.output_path
  function_name    = "${var.aws.default_tags.tags["Name"]}-record"
  handler          = "lambda_record.lambda_handler"
  memory_size      = 128
  role             = aws_iam_role.this-record.arn
  runtime          = "python3.11"
  source_code_hash = data.archive_file.this-record.output_base64sha256
  timeout          = 60
  environment {
    variables = {
      TAG_VALUE      = var.aws.default_tags.tags["Name"]
      HOSTED_ZONE_ID = var.vpc.route53.id
    }
  }
  depends_on = [aws_cloudwatch_log_group.this-record]
}

resource "aws_cloudwatch_event_rule" "this-record" {
  name                = var.aws.default_tags.tags["Name"]
  description         = "record"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "this-record" {
  rule      = aws_cloudwatch_event_rule.this-record.name
  target_id = "record"
  arn       = aws_lambda_function.this-record.arn
}

resource "aws_lambda_permission" "this-record" {
  statement_id  = "record"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this-record.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this-record.arn
}