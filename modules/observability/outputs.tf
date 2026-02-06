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