variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "flowops-infra"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain logs before deletion"
  type        = number
  default     = 180

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 365
    error_message = "log_retention_days must be between 30 and 365 days."
  }
}