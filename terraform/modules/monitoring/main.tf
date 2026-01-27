# SNS Topic pour les alarmes
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-${var.environment}-alarms"

  tags = {
    Name        = "${var.project_name}-alarms"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/${var.project_name}/${var.environment}/backend"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-backend-log"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "alb" {
  name              = "/${var.project_name}/${var.environment}/alb"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-alb-log"
    Environment = var.environment
  }
}


# Alarm CPU > 80% for backend ASG
resource "aws_cloudwatch_metric_alarm" "backend_high_cpu" {
  alarm_name        = "${var.project_name}-backend-high-cpu"
  alarm_description = "CPU > 80% sur backend"
  namespace         = "AWS/EC2"
  metric_name       = "CPUUtilization"
  dimensions = {
    AutoScalingGroupName = var.backend_asg_id
  }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

# Alarm pour 5xx ALB > 5%
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name        = "${var.project_name}-alb-5xx"
  alarm_description = "Plus de 5% de 5xx sur ALB"
  namespace         = "AWS/ApplicationELB"
  metric_name       = "HTTPCode_Target_5XX_Count"
  dimensions = {
    LoadBalancer = var.alb_arn
  }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_dashboard" "project_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"
  dashboard_body = file("${path.root}/../monitoring/cloudwatch-dashboard.json")
}

