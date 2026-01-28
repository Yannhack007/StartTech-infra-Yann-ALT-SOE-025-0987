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

# HTTPS Listener (requires ACM certificate)
# Note: You need to create an ACM certificate in your AWS account first
# Then uncomment this and update the certificate_arn
/*
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:region:account:certificate/certificate-id"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
*/

resource "aws_launch_template" "backend" {
  name_prefix            = "${var.project_name}-backend-lt-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type

  user_data = base64encode(file("${path.root}/../scripts/user-data.sh"))
  
  iam_instance_profile {
    name = aws_iam_instance_profile.backend.name
  }

  vpc_security_group_ids = [var.backend_sg_id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-backend-instance"
    }
  }
}

resource "aws_autoscaling_group" "backend" {
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = var.private_subnet_ids
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



data "aws_ami" "amazon-linux" {
 most_recent = true


 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }


 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}



