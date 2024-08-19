resource "aws_iam_role" "this-controlplane" {
  assume_role_policy = data.aws_iam_policy_document.this-assume["ec2"].json
  description        = "${var.aws.default_tags.tags["Name"]}-controlplane"
  name               = "${var.aws.default_tags.tags["Name"]}-controlplane"
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-controlplane"
    policy = data.aws_iam_policy_document.this-controlplane.json
  }
}

resource "aws_iam_instance_profile" "this-controlplane" {
  name = "${var.aws.default_tags.tags["Name"]}-controlplane"
  role = aws_iam_role.this-controlplane.name
}

resource "aws_security_group" "this-controlplane" {
  description = "${var.aws.default_tags.tags["Name"]}-controlplane"
  name        = "${var.aws.default_tags.tags["Name"]}-controlplane"
  tags        = { Name = "${var.aws.default_tags.tags["Name"]}-controlplane" }
  vpc_id      = var.vpc.vpc.id
}

resource "aws_vpc_security_group_egress_rule" "this-controlplane" {
  security_group_id = aws_security_group.this-controlplane.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "this-controlplane" {
  security_group_id = aws_security_group.this-controlplane.id

  referenced_security_group_id = aws_security_group.this-controlplane.id
  ip_protocol                  = "-1"
}

resource "aws_ec2_subnet_cidr_reservation" "this-controlplane" {
  cidr_block       = "${cidrhost(lookup(var.vpc.subnets.private, keys(var.vpc.subnets.private)[0], null)["cidr_block"], 10)}/32"
  subnet_id        = lookup(var.vpc.subnets.private, keys(var.vpc.subnets.private)[0], null)["id"]
  reservation_type = "explicit"
}

resource "aws_network_interface" "this-controlplane" {
  subnet_id       = lookup(var.vpc.subnets.private, keys(var.vpc.subnets.private)[0], null)["id"]
  private_ips     = [cidrhost(lookup(var.vpc.subnets.private, keys(var.vpc.subnets.private)[0], null)["cidr_block"], 10)]
  security_groups = [aws_security_group.this-controlplane.id]
  tags            = { Name = "${var.aws.default_tags.tags["Name"]}-controlplane" }
}

resource "aws_ebs_volume" "this-controlplane" {
  availability_zone = lookup(var.vpc.subnets.private, keys(var.vpc.subnets.private)[0], null)["availability_zone"]
  size              = "5"
  type              = "gp3"
  tags              = { Name = "${var.aws.default_tags.tags["Name"]}-controlplane" }
}

resource "aws_launch_template" "this-controlplane" {
  image_id = local.image_id
  name     = "${var.aws.default_tags.tags["Name"]}-controlplane"
  iam_instance_profile {
    name = aws_iam_instance_profile.this-controlplane.name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }
  user_data = base64encode(templatefile(
    "${path.module}/user_data.sh.tftpl", {
      NAME         = var.aws.default_tags.tags["Name"]
      BUCKET       = aws_s3_bucket.this.id
      INTERFACE_ID = aws_network_interface.this-controlplane.id
      PRIVATE_IP   = cidrhost(lookup(var.vpc.subnets.private, keys(var.vpc.subnets.private)[0], null)["cidr_block"], 10)
      PUBLIC_IP    = var.nat.eip[lookup(var.vpc.subnets.private, keys(var.vpc.subnets.private)[0], null)["availability_zone"]].public_ip
      VOLUME       = aws_ebs_volume.this-controlplane.id
    }
  ))
  vpc_security_group_ids = [aws_security_group.this-controlplane.id]
}

resource "aws_autoscaling_group" "this-controlplane" {
  capacity_rebalance        = false
  default_instance_warmup   = 60
  desired_capacity          = 1
  health_check_grace_period = 60
  max_size                  = 1
  min_size                  = 1
  name                      = "${var.aws.default_tags.tags["Name"]}-controlplane"
  vpc_zone_identifier       = [for each in var.vpc.subnets.private : each.id]
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this-controlplane.id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = local.instance_types
        content {
          instance_type = override.value
        }
      }
    }
  }
  tag {
    key                 = "Name"
    value               = "${var.aws.default_tags.tags["Name"]}-controlplane"
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes.io/cluster/${var.aws.default_tags.tags["Name"]}"
    value               = "owned"
    propagate_at_launch = true
  }
}

resource "aws_iam_role" "this-controlplane-autoscaling" {
  assume_role_policy = data.aws_iam_policy_document.this-assume["autoscaling"].json
  description        = "${var.aws.default_tags.tags["Name"]}-controlplane-autoscaling"
  name               = "${var.aws.default_tags.tags["Name"]}-controlplane-autoscaling"
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-controlplane-autoscaling"
    policy = data.aws_iam_policy_document.this-controlplane-autoscaling.json
  }
}

resource "aws_sns_topic" "this-controlplane-autoscaling" {
  name = "${var.aws.default_tags.tags["Name"]}-controlplane-autoscaling"
}

# autoscaling
resource "aws_sns_topic_subscription" "this-controlplane-autoscaling" {
  topic_arn = aws_sns_topic.this-controlplane-autoscaling.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.this-lambdas["gracefulshutdown"].arn
}

resource "aws_lambda_permission" "this-controlplane-autoscaling" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this-lambdas["gracefulshutdown"].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this-controlplane-autoscaling.arn
  statement_id  = "AllowExecutionFromSNS"
}

resource "aws_autoscaling_lifecycle_hook" "this-controlplane-autoscaling" {
  autoscaling_group_name  = aws_autoscaling_group.this-controlplane.name
  default_result          = "ABANDON"
  heartbeat_timeout       = 120
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  name                    = "${var.aws.default_tags.tags["Name"]}-controlplane"
  notification_target_arn = aws_sns_topic.this-controlplane-autoscaling.arn
  role_arn                = aws_iam_role.this-controlplane-autoscaling.arn
}

# interrupts
resource "aws_cloudwatch_event_rule" "this-controlplane-interrupt" {
  name        = "${var.aws.default_tags.tags["Name"]}-controlplane"
  description = "${var.aws.default_tags.tags["Name"]}-controlplane"
  event_pattern = jsonencode({
    detail-type = ["EC2 Spot Instance Interruption Warning"]
    source      = ["aws.ec2"]
    region      = [var.aws.region.name]
  })
}

resource "aws_cloudwatch_event_target" "this-controlplane-interrupt" {
  arn       = aws_lambda_function.this-lambdas["gracefulshutdown"].arn
  rule      = aws_cloudwatch_event_rule.this-controlplane-interrupt.name
  target_id = "interrupt"
}

resource "aws_lambda_permission" "this-controlplane-interrupt" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this-lambdas["gracefulshutdown"].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this-controlplane-interrupt.arn
  statement_id  = "AllowExecutionFromCloudWatch"
}
