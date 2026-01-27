variable "project_name" {
  description = "Project name for tagging"
  type = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EC2 instances"
  type        = list(string)
}

variable "backend_sg_id" {
  description = "Security Group ID for backend instances"
  type        = string
}

variable "alb_sg_id" {
  description = "Security Group ID for ALB"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 backend"
  type        = string
}
