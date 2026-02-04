variable "vpc_id" {
  description = "VPC ID for the ALB"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "Need at least two public subnets for high availability."
  }
}

variable "environment" {
  description = "Environment tag (dev/staging/prod)"
  type        = string
}

variable "alb_name" {
  description = "Name prefix for the ALB"
  type        = string
}
