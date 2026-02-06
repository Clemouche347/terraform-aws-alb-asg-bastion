module "bastion" {
  source = "../../modules/bastion"

  vpc_id           = var.vpc_id
  public_subnet_id = var.public_subnet_ids[0]
  allowed_ssh_cidr = var.allowed_ssh_cidr
  key_name         = var.key_name
  environment      = var.environment
}

module "alb" {
  source = "../../modules/alb"

  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  environment       = var.environment
  alb_name          = "app-alb-${var.environment}"
}

module "alb_logs" {
  source = "../../modules/observability"

  project_name       = var.project_name
  environment        = "dev"
  log_retention_days = 180 # 6 months retention
}

# NOTE: When you create your ALB module (Day 3), add this:
#
# module "alb" {
#   source = "../../modules/alb"
#   
#   # ... other variables ...
#   
#   enable_access_logs = true
#   access_logs_bucket = module.alb_logs.bucket_name
#   access_logs_prefix = "alb-logs"
# }

module "app_asg" {
  source = "../../modules/asg"

  vpc_id                = var.vpc_id
  private_subnet_ids    = var.private_subnet_ids
  desired_capacity      = var.desired_capacity
  min_size              = var.min_size
  max_size              = var.max_size
  environment           = var.environment
  alb_security_group_id = module.alb.alb_sg_id

  target_group_arns = [module.alb.target_group_arn]
}