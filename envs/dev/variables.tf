variable "vpc_id" {
  description = "VPC ID for the environment"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the bastion host"
  type        = string
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

variable "region" {
  description = "region chosen for the VPC"
  type        = string
  default     = "eu-west-3"
}

variable "target_group_arns" {
  description = "Target group ARNs to attach to the ASG"
  type        = list(string)
  default     = []
}