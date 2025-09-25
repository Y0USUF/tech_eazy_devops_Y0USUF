output "instance_public_ip" {
  value = aws_instance.dev_app.public_ip
}
output "bucket_name" {
  value = var.bucket_name
}