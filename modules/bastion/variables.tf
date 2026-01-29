variable "vpc_id" {
  type = string
  description = "id of the vpc"
}

variable "public_subnet_id" {
  type = string
  description = "id of the public subnet"
}

variable "allowed_ssh_cidr" {
  type = string
  description = "cidr of allowed ssh"
}

variable "key_name" {
  type = string
  description = "name of the key"
}

variable "instance_type" {
  type    = string
  description = "type of the instance"
  default = "t3.micro"
}
