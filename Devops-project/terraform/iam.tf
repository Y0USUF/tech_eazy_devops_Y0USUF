# Role A: Read-Only (S3 List + Get)
resource "aws_iam_role" "role_a" {
  name = "s3-read-only-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "role_a_policy" {
  name   = "s3-read-only-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:ListBucket", "s3:GetObject"]
      Resource = [
        "arn:aws:s3:::${var.ec2_logs_bucket_name}",
        "arn:aws:s3:::${var.ec2_logs_bucket_name}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "role_a_attach" {
  role       = aws_iam_role.role_a.name
  policy_arn = aws_iam_policy.role_a_policy.arn
}

# Role B: Uploader (S3 PutObject only)
resource "aws_iam_role" "role_b" {
  name = "s3-uploader-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "role_b_policy" {
  name   = "s3-uploader-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:PutObject"]
        Resource = "arn:aws:s3:::${var.ec2_logs_bucket_name}/*"
      },
      {
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.app_bucket_name}"
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.app_bucket_name}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "role_b_attach" {
  role       = aws_iam_role.role_b.name
  policy_arn = aws_iam_policy.role_b_policy.arn
}

# Instance Profile for Role B (attach to EC2s)
resource "aws_iam_instance_profile" "role_b_profile" {
  name = "s3-uploader-profile"
  role = aws_iam_role.role_b.name
}
resource "aws_iam_instance_profile" "role_b_profile" {
  name = "s3-uploader-profile"
  role = aws_iam_role.role_b.name
}
