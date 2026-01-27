variable "project_name" {
  type        = string
  description = "Project name for tagging"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets for Redis cluster"
}

variable "security_group_id" {
  type        = string
  description = "SG allowing access from backend EC2"
}
