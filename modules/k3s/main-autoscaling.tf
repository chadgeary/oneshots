resource "aws_iam_role" "this-autoscaling" {
  assume_role_policy = data.aws_iam_policy_document.this-assume["autoscaling"].json
  description        = "${var.aws.default_tags.tags["Name"]}-autoscaling"
  name               = "${var.aws.default_tags.tags["Name"]}-autoscaling"
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-autoscaling"
    policy = data.aws_iam_policy_document.this-autoscaling.json
  }
}

resource "aws_sns_topic" "this-autoscaling" {
  name = "${var.aws.default_tags.tags["Name"]}-autoscaling"
}

resource "aws_autoscaling_lifecycle_hook" "this-autoscaling" {
  for_each                = toset(["controlplane", "worker"])
  autoscaling_group_name  = "${var.aws.default_tags.tags["Name"]}-${each.key}"
  default_result          = "ABANDON"
  heartbeat_timeout       = 120
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  name                    = "${var.aws.default_tags.tags["Name"]}-interrupt"
  notification_target_arn = aws_sns_topic.this-autoscaling.arn
  role_arn                = aws_iam_role.this-autoscaling.arn
}

resource "aws_sns_topic_subscription" "this-autoscaling" {
  topic_arn = aws_sns_topic.this-autoscaling.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.this-lambdas["gracefulshutdown"].arn
}

resource "aws_lambda_permission" "this-autoscaling" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this-lambdas["gracefulshutdown"].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this-autoscaling.arn
  statement_id  = "AllowExecutionFromSNS"
}

# interrupts
resource "aws_cloudwatch_event_rule" "this-interrupt" {
  name        = "${var.aws.default_tags.tags["Name"]}-interrupt"
  description = "${var.aws.default_tags.tags["Name"]}-interrupt"
  event_pattern = jsonencode({
    detail-type = ["EC2 Spot Instance Interruption Warning"]
    source      = ["aws.ec2"]
    region      = [var.aws.region.name]
  })
}

resource "aws_cloudwatch_event_target" "this-interrupt" {
  arn       = aws_lambda_function.this-lambdas["gracefulshutdown"].arn
  rule      = aws_cloudwatch_event_rule.this-interrupt.name
  target_id = "interrupt"
}

resource "aws_lambda_permission" "this-interrupt" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this-lambdas["gracefulshutdown"].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this-interrupt.arn
  statement_id  = "AllowExecutionFromCloudWatch"
}
