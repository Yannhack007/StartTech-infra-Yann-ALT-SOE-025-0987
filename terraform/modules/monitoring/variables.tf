variable "project_name" {
  type        = string
  description = "Nom du projet pour tagging"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environnement"
}

variable "backend_asg_id" {
  type        = string
  description = "Auto Scaling Group du backend"
}

variable "alb_arn" {
  type        = string
  description = "ARN du ALB"
}

variable "log_retention_days" {
  type        = number
  default     = 14
  description = "Nombre de jours pour garder les logs"
}
