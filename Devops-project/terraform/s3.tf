# App JAR Bucket

resource "aws_s3_bucket" "app_bucket" {
  bucket        = var.app_bucket_name
  force_destroy = true

  tags = {
    Name = "app-jar-bucket"
  }
}

# EC2 Logs Bucket
resource "aws_s3_bucket" "ec2_logs_bucket" {
  bucket        = var.ec2_logs_bucket_name
  force_destroy = true

  tags = {
    Name = "ec2-logs-bucket"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ec2_logs_lifecycle" {
  bucket = aws_s3_bucket.ec2_logs_bucket.id

  rule {
    id     = "delete-logs"
    status = "Enabled"

    filter {
      prefix = "" # applies to all objects
    }

    expiration {
      days = 7
    }
  }
}

# ELB Logs Bucket

resource "aws_s3_bucket" "elb_logs_bucket" {
  bucket        = var.elb_logs_bucket_name
  force_destroy = true

  tags = {
    Name = "elb-logs-bucket"
  }
}

# Policy so ALB can write logs into the bucket
resource "aws_s3_bucket_policy" "elb_logs_policy" {
  bucket = aws_s3_bucket.elb_logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::718504428378:root" # ap-south-1 ELB log delivery account
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.elb_logs_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elb.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.elb_logs_bucket.arn
      }
    ]
  })
}

# To fetch current AWS Account ID dynamically
data "aws_caller_identity" "current" {}
