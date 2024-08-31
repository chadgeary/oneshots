resource "aws_security_group" "this-nodes" {
  description = "${var.aws.default_tags.tags["Name"]}-nodes"
  name        = "${var.aws.default_tags.tags["Name"]}-nodes"
  tags        = { Name = "${var.aws.default_tags.tags["Name"]}-nodes" }
  vpc_id      = var.vpc.vpc.id
}

resource "aws_vpc_security_group_egress_rule" "this-nodes" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.this-nodes.id
}

resource "aws_vpc_security_group_ingress_rule" "this-nodes-flannel" {
  from_port                    = 8472
  ip_protocol                  = "udp"
  referenced_security_group_id = aws_security_group.this-nodes.id
  security_group_id            = aws_security_group.this-nodes.id
  to_port                      = 8472
}

resource "aws_vpc_security_group_ingress_rule" "this-nodes-metrics" {
  from_port                    = 10250
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.this-nodes.id
  security_group_id            = aws_security_group.this-nodes.id
  to_port                      = 10250
}

resource "aws_security_group" "this-worker" {
  description = "${var.aws.default_tags.tags["Name"]}-worker"
  name        = "${var.aws.default_tags.tags["Name"]}-worker"
  tags        = { Name = "${var.aws.default_tags.tags["Name"]}-worker" }
  vpc_id      = var.vpc.vpc.id
}

resource "aws_iam_role" "this-worker" {
  assume_role_policy = data.aws_iam_policy_document.this-assume["ec2"].json
  description        = "${var.aws.default_tags.tags["Name"]}-worker"
  name               = "${var.aws.default_tags.tags["Name"]}-worker"
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-worker"
    policy = data.aws_iam_policy_document.this-worker.json
  }
}

resource "aws_iam_instance_profile" "this-worker" {
  name = "${var.aws.default_tags.tags["Name"]}-worker"
  role = aws_iam_role.this-worker.name
}

resource "aws_launch_template" "this-worker" {
  image_id               = local.worker_ami.id
  name                   = "${var.aws.default_tags.tags["Name"]}-worker"
  vpc_security_group_ids = [aws_security_group.this-nodes.id, aws_security_group.this-worker.id]
  block_device_mappings {
    device_name = local.worker_ami.root_device_name
    ebs {
      volume_size = var.k3s["worker"].volume_size
    }
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.this-worker.name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }
  user_data = base64encode(templatefile(
    "${path.module}/user_data-worker.sh.tftpl", {
      BUCKET     = aws_s3_bucket.this.id
      NAME       = var.aws.default_tags.tags["Name"]
      PRIVATE_IP = cidrhost(lookup(var.vpc.subnets.private, keys(var.vpc.subnets.private)[0], null)["cidr_block"], 10)
    }
  ))
}

resource "aws_autoscaling_group" "this-worker" {
  capacity_rebalance        = false
  default_instance_warmup   = 60
  desired_capacity          = floor((var.k3s["worker"].min_size + var.k3s["worker"].max_size) / 2)
  health_check_grace_period = 60
  max_size                  = var.k3s["worker"].max_size
  min_size                  = var.k3s["worker"].min_size
  name                      = "${var.aws.default_tags.tags["Name"]}-worker"
  vpc_zone_identifier       = [lookup(var.vpc.subnets.private, keys(var.vpc.subnets.private)[0], null)["id"]]
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this-worker.id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = var.k3s["worker"].instance_types
        content {
          instance_type = override.value
        }
      }
    }
  }
  tag {
    key                 = "Name"
    value               = "${var.aws.default_tags.tags["Name"]}-worker"
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes.io/cluster/${var.aws.default_tags.tags["Name"]}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes.io/nodegroup/${var.aws.default_tags.tags["Name"]}-worker"
    value               = "true"
    propagate_at_launch = true
  }
  depends_on = [data.aws_s3_object.this]
  lifecycle { ignore_changes = [desired_capacity] }
}
