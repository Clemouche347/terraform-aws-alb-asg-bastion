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

module "app_asg" {
  source = "../../modules/asg"

  vpc_id                = var.vpc_id
  private_subnet_ids    = var.private_subnet_ids
  desired_capacity      = var.desired_capacity
  min_size              = var.min_size
  max_size              = var.max_size
  environment           = var.environment
  alb_security_group_id = module.alb.alb_sg_id
  health_check_type     = "EC2"

  target_group_arns = [module.alb.target_group_arn]
}

# -----------------------------------------------------------
# CLOUDWATCH MONITORING (Day 4)
# -----------------------------------------------------------
module "cloudwatch_monitoring" {
  source = "../../modules/observability"

  project_name = var.project_name
  environment  = "dev"

  # SNS Notification Configuration
  alarm_email_endpoints = var.alarm_email_endpoints
  # alarm_sms_endpoints   = var.alarm_sms_endpoints  # Optional
  send_ok_notifications = true # Get notified when alarms recover

  # Resource Monitoring
  # alb_arn            = module.alb.arn              # Uncomment when ALB exists
  asg_name         = module.app_asg.asg_name
  ec2_instance_ids = [module.bastion.instance_id] # Monitor bastion

  # Alarm Configuration
  enable_alb_alarms = false # Set to true when ALB is deployed
  enable_asg_alarms = true
  enable_ec2_alarms = true # Monitor bastion host

  # Alarm Thresholds (customize as needed)
  cpu_threshold              = 80  # Alert at 80% CPU
  response_time_threshold    = 2.0 # Alert at 2 seconds
  unhealthy_target_threshold = 0   # Alert on any unhealthy target
  error_5xx_threshold        = 5.0 # Alert at 5% error rate

  # Evaluation Periods
  cpu_evaluation_periods              = 2 # 2 periods (10 min at 5 min intervals)
  unhealthy_target_evaluation_periods = 2
  response_time_evaluation_periods    = 3

  # Composite Alarm (alerts when multiple issues occur)
  create_composite_alarm = false # Set to true when both ALB and ASG exist

  # Common Tags
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "DevOps-Team"
    CostCenter  = "Engineering"
  }
}