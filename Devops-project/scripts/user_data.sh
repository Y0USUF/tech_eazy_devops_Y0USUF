#!/bin/bash
sudo apt update -y
sudo apt install -y openjdk-21-jdk maven git unzip curl

# Install AWS CLI v2
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
AWS_CLI=/usr/local/bin/aws

# Clone and build app
cd /home/ubuntu
git clone https://github.com/Trainings-TechEazy/test-repo-for-devops.git
cd test-repo-for-devops
mvn clean package

# Run app on port 80
sudo nohup java -jar target/hellomvc-0.0.1-SNAPSHOT.jar --server.port=80 > /home/ubuntu/app.log 2>&1 &

# Setup shutdown script
cat <<EOL > /usr/local/bin/shutdown_upload.sh
#!/bin/bash
$AWS_CLI s3 cp /var/log/cloud-init.log s3://${bucket_name}/ec2-logs/ --region ap-south-1
$AWS_CLI s3 cp /home/ubuntu/app.log s3://${bucket_name}/app/logs/ --region ap-south-1
EOL

chmod +x /usr/local/bin/shutdown_upload.sh

# Create systemd service to run on shutdown
cat <<EOL > /etc/systemd/system/upload-logs.service
[Unit]
Description=Upload logs to S3 on shutdown
DefaultDependencies=no
Before=shutdown.target reboot.target halt.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/shutdown_upload.sh
RemainAfterExit=yes

[Install]
WantedBy=halt.target reboot.target shutdown.target
EOL

# Enable service
systemctl enable upload-logs.service