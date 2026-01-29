module "bastion" {
  source = "../../modules/bastion"

  vpc_id           = var.vpc_id
  public_subnet_id = var.public_subnet_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
  key_name         = var.key_name
}

module "app_asg" {
  source = "../../modules/asg"

  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  desired_capacity   = 2
  min_size           = 1
  max_size           = 3
  environment        = "dev"
}
