resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "backend" {
  name     = "${var.project_name}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = "muchtodo_keypair"
  vpc_security_group_ids = [var.backend_sg_id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              # Installation du backend Go, start service...
              EOF

  tags = {
    Name = "${var.project_name}-backend"
  }
}

resource "aws_autoscaling_group" "backend" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  vpc_zone_identifier  = var.private_subnet_ids
  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.backend.arn]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-backend"
    propagate_at_launch = true
  }

  health_check_type         = "ELB"
  health_check_grace_period = 60
}

