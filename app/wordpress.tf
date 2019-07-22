resource "aws_iam_role" "app" {
  path = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com.cn"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3" {
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "arn:aws-cn:s3:::${var.app_s3}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws-cn:s3:::${var.app_s3}",
                "arn:aws-cn:s3:::${var.app_s3}/*"
            ]
        }
    ]
}
EOF
  role = aws_iam_role.app.id
}

resource "aws_iam_instance_profile" "app" {
  role = aws_iam_role.app.name
}

data "template_file" "wp_config" {
  template = templatefile("${path.module}/wp-config.php.tpl", {
    wp_s3 = var.app_s3
    region = var.region
    db_endpoint = var.db_endpoint
    db_username = var.db_username
    db_password = var.db_password
    cache_endpoint = aws_elasticache_cluster.redis.cache_nodes.0.address
  })
}

resource "aws_launch_template" "app" {
  name = "app"
  image_id = lookup(var.app_ami, var.region)
  instance_type = "t2.large"
  key_name = var.ec2_key_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.app.arn
  }

  # auto configuration
  user_data = base64encode(data.template_file.wp_config.rendered)

  vpc_security_group_ids = [data.terraform_remote_state.basic.outputs.app_sg_id]
}

resource "aws_lb_target_group" "app" {
  name = "app"
  port = 80
  protocol = "HTTP"
  vpc_id = data.terraform_remote_state.basic.outputs.vpc
}

resource "aws_autoscaling_group" "app" {
  name = "app"
  max_size = var.app_max_capacity
  min_size = 1
  desired_capacity = var.app_desired_capacity

  vpc_zone_identifier = data.terraform_remote_state.basic.outputs.app_subnet_ids

  launch_template {
    id = aws_launch_template.app.id
    version = "$Latest"
  }

  health_check_type = "ELB"
}

resource "aws_autoscaling_attachment" "app" {
  autoscaling_group_name = aws_autoscaling_group.app.id
  alb_target_group_arn = aws_lb_target_group.app.arn
}
