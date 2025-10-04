provider "aws" {
  region = "ap-south-1"
}

# Fetch Default VPC & Subnets

data "aws_vpc" "default" {
  default = true
}

# Fetch all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Fetch details for each subnet
data "aws_subnet" "all_subnets" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

# Pick the first subnet in ap-south-1a or ap-south-1b for t2.micro
locals {
  subnet_for_free_tier = [
    for s in data.aws_subnet.all_subnets :
    s.id if s.availability_zone == "ap-south-1a" || s.availability_zone == "ap-south-1b"
  ][0]
}


# Dynamic Ubuntu AMI

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}


# Security Group

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance (Free Tier)

resource "aws_instance" "dev_app" {
  count                  = var.instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = local.subnet_for_free_tier

  iam_instance_profile   = aws_iam_instance_profile.role_b_profile.name

  user_data = templatefile("${path.module}/../scripts/user_data.sh", {
    bucket_name     = var.ec2_logs_bucket_name
    app_bucket_name = var.app_bucket_name
  })

  tags = {
    Name = "DevOpsApp-${count.index + 1}"
  }
}

# Application Load Balancer

resource "aws_lb" "app_lb" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = data.aws_subnets.default.ids

  access_logs {
    bucket  = aws_s3_bucket.elb_logs_bucket.bucket
    prefix  = ""
    enabled = true
  }

  # Ensure bucket policy is applied before ELB creation
  depends_on = [aws_s3_bucket_policy.elb_logs_policy]

  tags = {
    Name = "AppLoadBalancer"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/hello"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "AppTargetGroup"
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "app_attach" {
  count             = var.instance_count
  target_group_arn  = aws_lb_target_group.app_tg.arn
  target_id         = aws_instance.dev_app[count.index].id
  port              = 80
}

# Outputs

output "instance_public_ips" {
  value = [for i in aws_instance.dev_app : i.public_ip]
}

output "bucket_name" {
  value = var.ec2_logs_bucket_name
}

output "app_bucket_name" {
  value = var.app_bucket_name
}

output "lb_dns" {
  value = aws_lb.app_lb.dns_name
}
