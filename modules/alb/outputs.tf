output "alb_dns" {
  description = "The DNS name of the ALB"
  value       = aws_lb.alb.dns_name
}

output "alb_arn" {
  value = aws_lb.alb.arna
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "target_group_arn" {
  value = aws_lb_target_group.asg_tg.arn
}