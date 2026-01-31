output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
output "instance_id" {
  description = "Bastion instance ID"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "Public IP of bastion host"
  value       = aws_instance.bastion.public_ip
}

output "security_group_id" {
  description = "Security group ID of bastion"
  value       = aws_security_group.bastion.id
}