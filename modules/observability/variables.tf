variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "flowops-infra"

    validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 32
    error_message = "project_name must be between 1 and 32 characters."
  }
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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
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

# -----------------------------------------------------------
# SNS Configuration
# -----------------------------------------------------------

variable "alarm_email_endpoints" {
  description = "List of email addresses to receive alarm notifications"
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
  description = "List of phone numbers (E.164 format) to receive alarm notifications"
  type        = list(string)
  default     = []
}

variable "sns_kms_key_id" {
  description = "KMS key ID for SNS topic encryption (optional)"
  type        = string
  default     = null
}

variable "send_ok_notifications" {
  description = "Send notifications when alarms return to OK state"
  type        = bool
  default     = false
}

# -----------------------------------------------------------
# Resource Identifiers
# -----------------------------------------------------------

variable "alb_arn" {
  description = "ARN of the Application Load Balancer to monitor"
  type        = string
  default     = null
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group to monitor"
  type        = string
  default     = null
}

variable "ec2_instance_ids" {
  description = "List of EC2 instance IDs to monitor"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------
# Alarm Configuration
# -----------------------------------------------------------

variable "alarm_period" {
  description = "Period in seconds for alarm evaluation (default: 300 = 5 minutes)"
  type        = number
  default     = 300

  validation {
    condition     = contains([60, 300, 900, 3600], var.alarm_period)
    error_message = "alarm_period must be 60, 300, 900, or 3600 seconds."
  }
}

# -----------------------------------------------------------
# ALB Alarm Thresholds
# -----------------------------------------------------------

variable "enable_alb_alarms" {
  description = "Enable ALB-related alarms"
  type        = bool
  default     = true
}

variable "unhealthy_target_threshold" {
  description = "Threshold for unhealthy target count alarm"
  type        = number
  default     = 0

  validation {
    condition     = var.unhealthy_target_threshold >= 0
    error_message = "unhealthy_target_threshold must be >= 0."
  }
}

variable "unhealthy_target_evaluation_periods" {
  description = "Number of periods to evaluate for unhealthy target alarm"
  type        = number
  default     = 2

  validation {
    condition     = var.unhealthy_target_evaluation_periods >= 1 && var.unhealthy_target_evaluation_periods <= 10
    error_message = "unhealthy_target_evaluation_periods must be between 1 and 10."
  }
}

variable "response_time_threshold" {
  description = "Threshold in seconds for target response time alarm"
  type        = number
  default     = 1.0

  validation {
    condition     = var.response_time_threshold > 0
    error_message = "response_time_threshold must be greater than 0."
  }
}

variable "response_time_evaluation_periods" {
  description = "Number of periods to evaluate for response time alarm"
  type        = number
  default     = 2

  validation {
    condition     = var.response_time_evaluation_periods >= 1 && var.response_time_evaluation_periods <= 10
    error_message = "response_time_evaluation_periods must be between 1 and 10."
  }
}

variable "error_5xx_threshold" {
  description = "Threshold percentage for 5XX error rate alarm (e.g., 5 for 5%)"
  type        = number
  default     = 5.0

  validation {
    condition     = var.error_5xx_threshold >= 0 && var.error_5xx_threshold <= 100
    error_message = "error_5xx_threshold must be between 0 and 100."
  }
}

# -----------------------------------------------------------
# ASG Alarm Thresholds
# -----------------------------------------------------------

variable "enable_asg_alarms" {
  description = "Enable ASG-related alarms"
  type        = bool
  default     = true
}

variable "cpu_threshold" {
  description = "Threshold percentage for CPU utilization alarm"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_threshold >= 0 && var.cpu_threshold <= 100
    error_message = "cpu_threshold must be between 0 and 100."
  }
}

variable "cpu_evaluation_periods" {
  description = "Number of periods to evaluate for CPU alarm"
  type        = number
  default     = 2

  validation {
    condition     = var.cpu_evaluation_periods >= 1 && var.cpu_evaluation_periods <= 10
    error_message = "cpu_evaluation_periods must be between 1 and 10."
  }
}

# -----------------------------------------------------------
# EC2 Alarm Configuration
# -----------------------------------------------------------

variable "enable_ec2_alarms" {
  description = "Enable EC2 instance-specific alarms"
  type        = bool
  default     = false
}

# -----------------------------------------------------------
# Advanced Configuration
# -----------------------------------------------------------

variable "create_composite_alarm" {
  description = "Create a composite alarm combining multiple conditions"
  type        = bool
  default     = false
}
