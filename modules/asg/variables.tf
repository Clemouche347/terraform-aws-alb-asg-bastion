variable "vpc_id" {
  description = "VPC ID where the Auto Scaling Group is created"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ASG instances"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 1
    error_message = "At least one private subnet ID must be provided."
  }
}

variable "instance_type" {
  description = "EC2 instance type for application instances"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 0
    error_message = "min_size must be >= 0."
  }
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 3

  validation {
    condition     = var.max_size >= 1
    error_message = "max_size must be >= 1."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_capacity >= var.min_size && var.desired_capacity <= var.max_size
    error_message = "desired_capacity must be between min_size and max_size."
  }
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "health_check_type" {
  description = "ASG health check type (EC2 or ELB)"
  type        = string
  default     = "ELB" # Changed from EC2

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be EC2 or ELB."
  }
}

variable "health_check_grace_period" {
  description = "Time (in seconds) before health checks start"
  type        = number
  default     = 300
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB (to allow HTTP traffic)"
  type        = string
  default     = null  
}