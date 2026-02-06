# Data sources for AWS account info and ELB service account
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "alb_logs" { #- The bucket itself
  bucket = "${var.project_name}-alb-logs-${var.environment}-${data.aws_caller_identity.current.account_id}"

    tags = {
    Name        = "${var.project_name}-alb-logs"
    Environment = var.environment
    Purpose     = "ALB Access Logs"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" { #- Security
  bucket = aws_s3_bucket.alb_logs.id
  block_public_acls       = true
  block_public_policy    = true
  ignore_public_acls    = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "alb_logs" { #- Data protection
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
      status = "Enabled"
  }
}  


resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" { #- Cost optimization
  bucket = aws_s3_bucket.alb_logs.id 
    rule {
    id     = "alb-log-lifecycle"
    status = "Enabled"

    # Apply to all objects in the bucket
    filter {}

    # Transition to Infrequent Access after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Delete after 180 days (configurable)
    expiration {
      days = var.log_retention_days
    }
  }
}


resource "aws_s3_bucket_policy" "alb_logs" { #- ALB write permissions
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.alb_logs]
}

# Cloudwatch

# ============================================================
# SNS TOPIC FOR ALARMS
# ============================================================

resource "aws_sns_topic" "cloudwatch_alarms" {
  name              = "${var.project_name}-${var.environment}-cloudwatch-alarms"
  display_name      = "CloudWatch Alarms for ${var.project_name} ${var.environment}"
  kms_master_key_id = var.sns_kms_key_id

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-cloudwatch-alarms"
      Environment = var.environment
      Purpose     = "CloudWatch Alarm Notifications"
    }
  )
}

# Email subscription
resource "aws_sns_topic_subscription" "alarm_email" {
  for_each = toset(var.alarm_email_endpoints)

  topic_arn = aws_sns_topic.cloudwatch_alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

# Optional: SMS subscription
resource "aws_sns_topic_subscription" "alarm_sms" {
  for_each = toset(var.alarm_sms_endpoints)

  topic_arn = aws_sns_topic.cloudwatch_alarms.arn
  protocol  = "sms"
  endpoint  = each.value
}

# ============================================================
# CLOUDWATCH DASHBOARD
# ============================================================

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = flatten([
      # ALB Metrics (if ALB is provided)
      [for _ in range(var.alb_arn != null ? 1 : 0) : [
        {
          type   = "metric"
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/ApplicationELB", "RequestCount", {
                stat  = "Sum"
                label = "Total Requests"
              }]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "ALB - Request Count"
            period  = 300
            yAxis = {
              left = { min = 0 }
            }
          }
        },
        {
          type   = "metric"
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/ApplicationELB", "TargetResponseTime", {
                stat  = "Average"
                label = "Avg Response Time"
              }],
              ["...", { stat = "p99", label = "P99 Response Time" }]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "ALB - Response Time"
            period  = 300
            yAxis = {
              left = { min = 0 }
            }
          }
        },
        {
          type   = "metric"
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", {
                stat  = "Sum"
                label = "2XX Responses"
              }],
              [".", "HTTPCode_Target_4XX_Count", {
                stat  = "Sum"
                label = "4XX Responses"
              }],
              [".", "HTTPCode_Target_5XX_Count", {
                stat  = "Sum"
                label = "5XX Responses"
              }]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "ALB - HTTP Response Codes"
            period  = 300
          }
        },
        {
          type   = "metric"
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/ApplicationELB", "HealthyHostCount", {
                stat  = "Average"
                label = "Healthy Targets"
              }],
              [".", "UnHealthyHostCount", {
                stat  = "Average"
                label = "Unhealthy Targets"
              }]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "ALB - Target Health"
            period  = 300
            yAxis = {
              left = { min = 0 }
            }
          }
        },
        {
          type   = "metric"
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/ApplicationELB", "ActiveConnectionCount", {
                stat  = "Sum"
                label = "Active Connections"
              }],
              [".", "NewConnectionCount", {
                stat  = "Sum"
                label = "New Connections"
              }]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "ALB - Connections"
            period  = 300
          }
        }
      ]],

      # ASG Metrics (if ASG is provided)
      [for _ in range(var.asg_name != null ? 1 : 0) : [
        {
          type   = "metric"
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", var.asg_name, { stat = "Average", label = "Desired Capacity" }],
              [".", "GroupInServiceInstances", "AutoScalingGroupName", var.asg_name, { stat = "Average", label = "In-Service Instances" }],
              [".", "GroupMinSize", "AutoScalingGroupName", var.asg_name, { stat = "Average", label = "Min Size" }],
              [".", "GroupMaxSize", "AutoScalingGroupName", var.asg_name, { stat = "Average", label = "Max Size" }]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "Auto Scaling Group - Capacity"
            period  = 300
            yAxis = {
              left = { min = 0 }
            }
          }
        },
        {
          type   = "metric"
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/AutoScaling", "GroupPendingInstances", "AutoScalingGroupName", var.asg_name, { stat = "Average", label = "Pending" }],
              [".", "GroupTerminatingInstances", "AutoScalingGroupName", var.asg_name, { stat = "Average", label = "Terminating" }]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "Auto Scaling Group - Instance Lifecycle"
            period  = 300
          }
        }
      ]],

      # EC2 CPU Metrics (if instance IDs provided)
      [for _ in range(length(var.ec2_instance_ids) > 0 ? 1 : 0) : [
        {
          type   = "metric"
          width  = 24
          height = 6
          properties = {
            metrics = [
              for instance_id in var.ec2_instance_ids :
              ["AWS/EC2", "CPUUtilization", "InstanceId", instance_id, { stat = "Average", label = "CPU ${instance_id}" }]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "EC2 Instances - CPU Utilization"
            period  = 300
            yAxis = {
              left = { min = 0, max = 100 }
            }
          }
        }
      ]]
    ])
  })
}

# ============================================================
# ALB ALARMS
# ============================================================

# Alarm: Unhealthy Target Count
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  count = var.alb_arn != null && var.enable_alb_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-unhealthy-targets"
  alarm_description   = "Alert when ALB has unhealthy targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.unhealthy_target_evaluation_periods
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.unhealthy_target_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = regex("loadbalancer/(.*)", var.alb_arn)[0]
  }

  alarm_actions = [aws_sns_topic.cloudwatch_alarms.arn]
  ok_actions    = var.send_ok_notifications ? [aws_sns_topic.cloudwatch_alarms.arn] : []

  tags = merge(
    var.common_tags,
    {
      Name        = "alb-unhealthy-targets"
      Environment = var.environment
      Severity    = "High"
    }
  )
}

# Alarm: High Response Time
resource "aws_cloudwatch_metric_alarm" "alb_high_response_time" {
  count = var.alb_arn != null && var.enable_alb_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-high-response-time"
  alarm_description   = "Alert when ALB target response time is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.response_time_evaluation_periods
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.response_time_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = regex("loadbalancer/(.*)", var.alb_arn)[0]
  }

  alarm_actions = [aws_sns_topic.cloudwatch_alarms.arn]
  ok_actions    = var.send_ok_notifications ? [aws_sns_topic.cloudwatch_alarms.arn] : []

  tags = merge(
    var.common_tags,
    {
      Name        = "alb-high-response-time"
      Environment = var.environment
      Severity    = "Medium"
    }
  )
}

# Alarm: High 5XX Error Rate
resource "aws_cloudwatch_metric_alarm" "alb_high_5xx_errors" {
  count = var.alb_arn != null && var.enable_alb_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-high-5xx-errors"
  alarm_description   = "Alert when ALB 5XX error rate is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = var.error_5xx_threshold

  metric_query {
    id          = "error_rate"
    expression  = "(m2/m1)*100"
    label       = "5XX Error Rate (%)"
    return_data = true
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = var.alarm_period
      stat        = "Sum"
      dimensions = {
        LoadBalancer = regex("loadbalancer/(.*)", var.alb_arn)[0]
      }
    }
  }

  metric_query {
    id = "m2"
    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = var.alarm_period
      stat        = "Sum"
      dimensions = {
        LoadBalancer = regex("loadbalancer/(.*)", var.alb_arn)[0]
      }
    }
  }

  alarm_actions = [aws_sns_topic.cloudwatch_alarms.arn]
  ok_actions    = var.send_ok_notifications ? [aws_sns_topic.cloudwatch_alarms.arn] : []

  tags = merge(
    var.common_tags,
    {
      Name        = "alb-high-5xx-errors"
      Environment = var.environment
      Severity    = "High"
    }
  )
}

# ============================================================
# ASG ALARMS
# ============================================================

# Alarm: ASG CPU Utilization
resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
  count = var.asg_name != null && var.enable_asg_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-asg-high-cpu"
  alarm_description   = "Alert when ASG CPU utilization is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.cloudwatch_alarms.arn]
  ok_actions    = var.send_ok_notifications ? [aws_sns_topic.cloudwatch_alarms.arn] : []

  tags = merge(
    var.common_tags,
    {
      Name        = "asg-high-cpu"
      Environment = var.environment
      Severity    = "Medium"
    }
  )
}

# Alarm: No Healthy Instances
resource "aws_cloudwatch_metric_alarm" "asg_no_healthy_instances" {
  count = var.asg_name != null && var.enable_asg_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-asg-no-healthy-instances"
  alarm_description   = "Alert when ASG has no in-service instances"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.cloudwatch_alarms.arn]
  ok_actions    = var.send_ok_notifications ? [aws_sns_topic.cloudwatch_alarms.arn] : []

  tags = merge(
    var.common_tags,
    {
      Name        = "asg-no-healthy-instances"
      Environment = var.environment
      Severity    = "Critical"
    }
  )
}

# ============================================================
# EC2 INSTANCE ALARMS
# ============================================================

# Alarm: High CPU on individual instances
resource "aws_cloudwatch_metric_alarm" "ec2_high_cpu" {
  for_each = var.enable_ec2_alarms ? toset(var.ec2_instance_ids) : []

  alarm_name          = "${var.project_name}-${var.environment}-ec2-high-cpu-${each.value}"
  alarm_description   = "Alert when EC2 instance ${each.value} CPU is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = each.value
  }

  alarm_actions = [aws_sns_topic.cloudwatch_alarms.arn]
  ok_actions    = var.send_ok_notifications ? [aws_sns_topic.cloudwatch_alarms.arn] : []

  tags = merge(
    var.common_tags,
    {
      Name        = "ec2-high-cpu-${each.value}"
      Environment = var.environment
      Severity    = "Medium"
      InstanceId  = each.value
    }
  )
}

# Alarm: Instance Status Check Failed
resource "aws_cloudwatch_metric_alarm" "ec2_status_check_failed" {
  for_each = var.enable_ec2_alarms ? toset(var.ec2_instance_ids) : []

  alarm_name          = "${var.project_name}-${var.environment}-ec2-status-check-${each.value}"
  alarm_description   = "Alert when EC2 instance ${each.value} status check fails"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = each.value
  }

  alarm_actions = [aws_sns_topic.cloudwatch_alarms.arn]
  ok_actions    = var.send_ok_notifications ? [aws_sns_topic.cloudwatch_alarms.arn] : []

  tags = merge(
    var.common_tags,
    {
      Name        = "ec2-status-check-${each.value}"
      Environment = var.environment
      Severity    = "High"
      InstanceId  = each.value
    }
  )
}

# ============================================================
# COMPOSITE ALARM (Optional)
# ============================================================

# Composite alarm that triggers when multiple conditions are met
resource "aws_cloudwatch_composite_alarm" "critical_infrastructure_health" {
  count = var.create_composite_alarm && var.alb_arn != null && var.asg_name != null ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-critical-health"
  alarm_description   = "Composite alarm for critical infrastructure health issues"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]
  ok_actions          = var.send_ok_notifications ? [aws_sns_topic.cloudwatch_alarms.arn] : []

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.alb_unhealthy_targets[0].alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.asg_no_healthy_instances[0].alarm_name})"

  tags = merge(
    var.common_tags,
    {
      Name        = "critical-infrastructure-health"
      Environment = var.environment
      Severity    = "Critical"
    }
  )
}

