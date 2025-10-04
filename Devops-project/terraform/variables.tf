# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "ubuntu"
}

variable "instance_count" {
  description = "Number of EC2 instances for scaling"
  type        = number
  default     = 3
}

# S3 Buckets
variable "app_bucket_name" {
  description = "S3 bucket name for storing the application JAR"
  type        = string
  default     = "techeazy-app-jar-bucket" # must be globally unique
}

variable "ec2_logs_bucket_name" {
  description = "S3 bucket name for EC2 logs"
  type        = string
  default     = "techeazy-ec2-logs" # must be globally unique
}

variable "elb_logs_bucket_name" {
  description = "S3 bucket name for ELB logs"
  type        = string
  default     = "techeazy-elb-logs" # must be globally unique
}
