resource "aws_iam_role" "this-controlplane" {
  assume_role_policy = data.aws_iam_policy_document.this-controlplane-assume.json
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
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
  user_data              = base64encode(local.user_data)
  vpc_security_group_ids = [aws_security_group.this-controlplane.id]
}

resource "aws_autoscaling_group" "this-controlplane" {
  capacity_rebalance  = false
  desired_capacity    = 3
  max_size            = 3
  min_size            = 3
  name                = "${var.aws.default_tags.tags["Name"]}-controlplane"
  suspended_processes = ["AZRebalance"]
  vpc_zone_identifier = [for each in var.vpc.subnets.private : each.id]
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
