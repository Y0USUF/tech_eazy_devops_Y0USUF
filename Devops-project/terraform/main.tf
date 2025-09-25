provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow SSH and HTTP"

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

resource "aws_instance" "dev_app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  iam_instance_profile = aws_iam_instance_profile.role_b_profile.name

  user_data = templatefile("${path.module}/../scripts/user_data.sh", {
    bucket_name = var.bucket_name
  })

  tags = {
    Name = "DevOpsApp"
  }
}

output "public_ip" {
  value = aws_instance.dev_app.public_ip
}
