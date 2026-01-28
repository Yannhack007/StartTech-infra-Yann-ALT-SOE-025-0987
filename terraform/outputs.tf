# VPC & Networking Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private app subnet IDs"
  value       = module.networking.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  description = "Private data subnet IDs"
  value       = module.networking.private_data_subnet_ids
}

# ALB & Backend Compute Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.compute.alb_arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.asg_id
}

output "target_group_arn" {
  description = "ARN of the backend target group"
  value       = module.compute.target_group_arn
}

# Frontend Storage & CDN Outputs
output "frontend_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = module.storage.frontend_bucket_name
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.storage.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (used for cache invalidation)"
  value       = module.storage.cloudfront_distribution_id
}

# Caching (Redis) Outputs
output "redis_endpoint" {
  description = "Redis cluster endpoint address"
  value       = module.caching.redis_endpoint
}

output "redis_port" {
  description = "Redis cluster port"
  value       = module.caching.redis_port
}

# Monitoring Outputs
output "backend_log_group_name" {
  description = "CloudWatch log group for backend"
  value       = module.monitoring.backend_log_group_name
}

output "alb_log_group_name" {
  description = "CloudWatch log group for ALB"
  value       = module.monitoring.alb_log_group_name
}

output "sns_alarm_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  value       = module.monitoring.sns_alarm_topic_arn
}

# ECR Repository Output
output "ecr_repository_url" {
  description = "ECR repository URL for pushing Docker images"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.backend.name
}

# Summary Output
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    backend_url        = "http://${module.compute.alb_dns_name}"
    frontend_url       = "https://${module.storage.cloudfront_domain_name}"
    redis_endpoint     = module.caching.redis_endpoint
    log_group_backend  = module.monitoring.backend_log_group_name
    ecr_repository_url = aws_ecr_repository.backend.repository_url
    region             = data.aws_region.current.name
    environment        = var.environment
  }
}
