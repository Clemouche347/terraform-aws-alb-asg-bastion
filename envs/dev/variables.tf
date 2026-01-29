variable "vpc_id" {
  description = "VPC ID for the environment"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the bastion host"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the bastion"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}
