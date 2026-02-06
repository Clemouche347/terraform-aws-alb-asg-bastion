output "bucket_name" {
  description = "Name of the S3 bucket for ALB access logs"
  value       = aws_s3_bucket.alb_logs.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket for ALB access logs"
  value       = aws_s3_bucket.alb_logs.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name"
  value       = aws_s3_bucket.alb_logs.bucket_domain_name
}

output "lifecycle_rule_id" {
  description = "ID of the lifecycle rule"
  value       = "alb-log-lifecycle"
}

# ============================================================
# CLOUDWATCH MONITORING MODULE - OUTPUTS
# ============================================================

# -----------------------------------------------------------
# SNS Topic Outputs
# -----------------------------------------------------------

output "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.cloudwatch_alarms.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.cloudwatch_alarms.name
}

# -----------------------------------------------------------
# Dashboard Outputs
# -----------------------------------------------------------

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "dashboard_url" {
  description = "Direct URL to the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

# -----------------------------------------------------------
# ALB Alarm Outputs
# -----------------------------------------------------------

output "alb_unhealthy_targets_alarm_arn" {
  description = "ARN of the ALB unhealthy targets alarm"
  value       = var.alb_arn != null && var.enable_alb_alarms ? aws_cloudwatch_metric_alarm.alb_unhealthy_targets[0].arn : null
}

output "alb_high_response_time_alarm_arn" {
  description = "ARN of the ALB high response time alarm"
  value       = var.alb_arn != null && var.enable_alb_alarms ? aws_cloudwatch_metric_alarm.alb_high_response_time[0].arn : null
}

output "alb_high_5xx_errors_alarm_arn" {
  description = "ARN of the ALB high 5XX errors alarm"
  value       = var.alb_arn != null && var.enable_alb_alarms ? aws_cloudwatch_metric_alarm.alb_high_5xx_errors[0].arn : null
}

# -----------------------------------------------------------
# ASG Alarm Outputs
# -----------------------------------------------------------

output "asg_high_cpu_alarm_arn" {
  description = "ARN of the ASG high CPU alarm"
  value       = var.asg_name != null && var.enable_asg_alarms ? aws_cloudwatch_metric_alarm.asg_high_cpu[0].arn : null
}

output "asg_no_healthy_instances_alarm_arn" {
  description = "ARN of the ASG no healthy instances alarm"
  value       = var.asg_name != null && var.enable_asg_alarms ? aws_cloudwatch_metric_alarm.asg_no_healthy_instances[0].arn : null
}

# -----------------------------------------------------------
# EC2 Alarm Outputs
# -----------------------------------------------------------

output "ec2_alarm_arns" {
  description = "Map of EC2 instance IDs to their alarm ARNs"
  value = var.enable_ec2_alarms ? {
    for instance_id in var.ec2_instance_ids :
    instance_id => {
      high_cpu_alarm        = aws_cloudwatch_metric_alarm.ec2_high_cpu[instance_id].arn
      status_check_alarm    = aws_cloudwatch_metric_alarm.ec2_status_check_failed[instance_id].arn
    }
  } : {}
}

# -----------------------------------------------------------
# Composite Alarm Outputs
# -----------------------------------------------------------

output "composite_alarm_arn" {
  description = "ARN of the composite alarm (if created)"
  value       = var.create_composite_alarm && var.alb_arn != null && var.asg_name != null ? aws_cloudwatch_composite_alarm.critical_infrastructure_health[0].arn : null
}

# -----------------------------------------------------------
# Summary Outputs
# -----------------------------------------------------------

output "alarm_count" {
  description = "Total number of alarms created"
  value = (
    (var.alb_arn != null && var.enable_alb_alarms ? 3 : 0) +
    (var.asg_name != null && var.enable_asg_alarms ? 2 : 0) +
    (var.enable_ec2_alarms ? length(var.ec2_instance_ids) * 2 : 0) +
    (var.create_composite_alarm && var.alb_arn != null && var.asg_name != null ? 1 : 0)
  )
}

output "monitoring_summary" {
  description = "Summary of monitoring configuration"
  value = {
    dashboard_enabled     = true
    alb_monitoring        = var.alb_arn != null && var.enable_alb_alarms
    asg_monitoring        = var.asg_name != null && var.enable_asg_alarms
    ec2_monitoring        = var.enable_ec2_alarms && length(var.ec2_instance_ids) > 0
    composite_alarm       = var.create_composite_alarm
    email_notifications   = length(var.alarm_email_endpoints)
    sms_notifications     = length(var.alarm_sms_endpoints)
    total_alarms          = (
      (var.alb_arn != null && var.enable_alb_alarms ? 3 : 0) +
      (var.asg_name != null && var.enable_asg_alarms ? 2 : 0) +
      (var.enable_ec2_alarms ? length(var.ec2_instance_ids) * 2 : 0) +
      (var.create_composite_alarm && var.alb_arn != null && var.asg_name != null ? 1 : 0)
    )
  }
}
