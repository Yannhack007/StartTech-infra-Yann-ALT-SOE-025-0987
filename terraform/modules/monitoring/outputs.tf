output "backend_log_group_name" {
  value       = aws_cloudwatch_log_group.backend.name
  description = "CloudWatch log group name for backend"
}

output "alb_log_group_name" {
  value       = aws_cloudwatch_log_group.alb.name
  description = "CloudWatch log group name for ALB"
}

output "dashboard_name" {
  value       = aws_cloudwatch_dashboard.project_dashboard.dashboard_name
  description = "CloudWatch dashboard name"
}

output "sns_alarm_topic_arn" {
  value       = aws_sns_topic.alarms.arn
  description = "SNS topic ARN for CloudWatch alarms"
}
