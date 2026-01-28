variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "starttech"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app subnets (EC2)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_data_subnet_cidrs" {
  description = "CIDR blocks for private data subnets (RDS, Redis, MongoDB)"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "frontend_bucket_name" {
  description = "S3 bucket name for frontend (must be globally unique)"
  type        = string
  default     = "starttech-frontend-prod"
}

variable "backend_instance_type" {
  description = "EC2 instance type for backend"
  type        = string
  default     = "t3.micro"
}

variable "backend_asg_min_size" {
  description = "Minimum number of instances in backend ASG"
  type        = number
  default     = 2
}

variable "backend_asg_max_size" {
  description = "Maximum number of instances in backend ASG"
  type        = number
  default     = 4
}

variable "backend_asg_desired_capacity" {
  description = "Desired number of instances in backend ASG"
  type        = number
  default     = 2
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_mongodb_atlas" {
  description = "Enable MongoDB Atlas (false = create MongoDB on EC2)"
  type        = bool
  default     = true
}

variable "mongodb_atlas_connection_string" {
  description = "MongoDB Atlas connection string (if enabled)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "starttech"
    ManagedBy   = "terraform"
    CreatedDate = "2026-01-28"
  }
}
