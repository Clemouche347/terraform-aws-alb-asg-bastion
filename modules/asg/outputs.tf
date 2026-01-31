output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.arn
}

output "security_group_id" {
  description = "Security group ID for app instances"
  value       = aws_security_group.app.id
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app.id
}