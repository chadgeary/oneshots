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
  network_interfaces {
    network_interface_id = aws_network_interface.this-controlplane.id
  }
  user_data = base64encode(templatefile(
    "${path.module}/user_data.sh.tftpl", {
      NAME       = var.aws.default_tags.tags["Name"],
      BUCKET     = aws_s3_bucket.this.id,
      PRIVATE_IP = cidrhost(lookup(var.vpc.subnets.private, keys(var.vpc.subnets.private)[0], null)["cidr_block"], 10)
      PUBLIC_IP  = var.nat.eip[lookup(var.vpc.subnets.private, keys(var.vpc.subnets.private)[0], null)["availability_zone"]].public_ip
    }
  ))
}

resource "aws_autoscaling_group" "this-controlplane" {
  availability_zones = [lookup(var.vpc.subnets.private, keys(var.vpc.subnets.private)[0], null)["availability_zone"]]
  capacity_rebalance = false
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  name               = "${var.aws.default_tags.tags["Name"]}-controlplane"
  initial_lifecycle_hook {
    name                    = "${var.aws.default_tags.tags["Name"]}-controlplane"
    default_result          = "ABANDON"
    heartbeat_timeout       = 300
    lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
    notification_target_arn = aws_sns_topic.this-controlplane.arn
    role_arn                = aws_iam_role.this-controlplane-scaledown.arn
  }
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

resource "aws_iam_role" "this-controlplane-scaledown" {
  assume_role_policy = data.aws_iam_policy_document.this-assume["autoscaling"].json
  description        = "${var.aws.default_tags.tags["Name"]}-controlplane-scaledown"
  name               = "${var.aws.default_tags.tags["Name"]}-controlplane-scaledown"
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-controlplane-scaledown"
    policy = data.aws_iam_policy_document.this-controlplane-scaledown.json
  }
}

resource "aws_sns_topic" "this-controlplane" {
  name = "${var.aws.default_tags.tags["Name"]}-controlplane"
}
