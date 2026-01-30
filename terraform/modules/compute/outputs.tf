output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.backend.arn
}

output "asg_id" {
  value = aws_autoscaling_group.backend.id
}


