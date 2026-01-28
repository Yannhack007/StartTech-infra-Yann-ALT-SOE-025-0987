output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs"
}

output "private_app_subnet_ids" {
  value       = aws_subnet.private_app[*].id
  description = "Private app subnet IDs"
}

output "private_data_subnet_ids" {
  value       = aws_subnet.private_data[*].id
  description = "Private data subnet IDs"
}

output "alb_sg_id" {
  value       = aws_security_group.alb.id
  description = "ALB security group ID"
}

output "backend_sg_id" {
  value       = aws_security_group.backend.id
  description = "Backend security group ID"
}

output "redis_sg_id" {
  value       = aws_security_group.redis.id
  description = "Redis security group ID"
}
