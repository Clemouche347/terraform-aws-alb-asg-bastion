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
    value       = module.alb.alb_dns_name
  }