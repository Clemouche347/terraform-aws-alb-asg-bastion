# Data sources for AWS account info and ELB service account
data "aws_caller_identity" "current" {}

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