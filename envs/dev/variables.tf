variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "flowops-infra"
}

variable "region" {
  description = "region chosen for the VPC"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID for the environment"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (at least 2 for ALB high availability)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least 2 public subnets required for ALB high availability."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the ASG"
  type        = list(string)
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the bastion"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "desired_capacity" {
  description = "Desired capacity for ASG"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum size for ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size for ASG"
  type        = number
  default     = 3
}

# -----------------------------------------------------------
# CloudWatch Monitoring Configuration
# -----------------------------------------------------------

variable "alarm_email_endpoints" {
  description = "List of email addresses to receive CloudWatch alarm notifications"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for email in var.alarm_email_endpoints :
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

variable "alarm_sms_endpoints" {
  description = "List of phone numbers (E.164 format, e.g., +33612345678) to receive alarm notifications"
  type        = list(string)
  default     = []
}
