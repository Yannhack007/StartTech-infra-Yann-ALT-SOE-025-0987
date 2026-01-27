variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/prod)"
  type        = string
  default     = "dev"
}

variable "frontend_bucket_name" {
  description = "Name of S3 bucket for frontend"
  type        = string
}
