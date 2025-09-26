variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "techeazy-ec2logs" # must be globally unique
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket        = var.bucket_name
  force_destroy = true  # allows terraform destroy even if objects exist

  tags = {
    Name = "logs-bucket"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs_bucket.id

  rule {
    id     = "delete-logs"
    status = "Enabled"

    filter {
      prefix = "" # all objects in the bucket
    }

    expiration {
      days = 7
    }
  }
}
