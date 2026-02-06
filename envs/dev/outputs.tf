output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion.public_ip
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion"
  value       = module.bastion.instance_id
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.app_asg.asg_name
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns
}

output "alb_logs_bucket_name" {
  description = "S3 bucket name for ALB access logs"
  value       = module.alb_logs.bucket_name
}

output "alb_logs_bucket_arn" {
  description = "S3 bucket ARN for ALB access logs"
  value       = module.alb_logs.bucket_arn
}

output "alb_logs_bucket_info" {
  description = "Complete info about ALB logs bucket"
  value = {
    bucket_name        = module.alb_logs.bucket_name
    bucket_arn         = module.alb_logs.bucket_arn
    lifecycle_rule     = "30d→IA, 90d→Glacier, 180d→Delete"
    public_access      = "Blocked"
    versioning_enabled = "Yes"
  }
}