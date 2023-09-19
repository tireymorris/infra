variable "region" {
  description = "The AWS region to create resources in."
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name to use in resource names"
  default     = "projectname"
}

variable "availability_zones" {
  description = "Availability zones"
  default     = ["us-east-1a", "us-east-1c"]
}

variable "ecs_backend_retention_days" {
  description = "Retention period for backend logs"
  default     = 30
}

variable "ecs_frontend_retention_days" {
  description = "Retention period for frontend logs"
  default     = 30
}

variable "rds_username" {
  description = "Username for the RDS database"
}

variable "rds_password" {
  description = "Password for the RDS database"
}

variable "AWS_ACCESS_KEY" {
  description = "AWS access key"
}

variable "AWS_SECRET_KEY" {
  description = "AWS secret key"
}

variable "domain" {
  description = "Domain where the app is hosted "
}

variable "subdomain" {
  description = "Subdomain where the app is hosted"
}

variable "debug" {
  description = "Debug mode"
  default     = false
}
