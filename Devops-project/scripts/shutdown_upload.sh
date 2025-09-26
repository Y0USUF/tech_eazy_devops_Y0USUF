#!/bin/bash
BUCKET_NAME="${bucket_name}"

# Upload EC2 logs
aws s3 cp /var/log/cloud-init.log s3://$BUCKET_NAME/ec2-logs/ --region ap-south-1

# Upload App logs
aws s3 cp /home/ubuntu/app.log s3://$BUCKET_NAME/app/logs/ --region ap-south-1