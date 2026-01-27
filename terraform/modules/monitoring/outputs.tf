output "backend_log_group" {
  value = aws_cloudwatch_log_group.backend.name
}

output "alb_log_group" {
  value = aws_cloudwatch_log_group.alb.name
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.project_dashboard.dashboard_name
}

output "sns_topic_arn" {
  value       = aws_sns_topic.alarms.arn
  description = "ARN du topic SNS pour les alarmes"
}
