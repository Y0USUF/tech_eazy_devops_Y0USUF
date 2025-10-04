#!/bin/bash
# Update system
sudo apt update -y
sudo apt install -y openjdk-21-jdk unzip curl

# Install AWS CLI v2
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
AWS_CLI=/usr/local/bin/aws

# Path setup
APP_PATH="/home/ubuntu/app.jar"
APP_LOG="/home/ubuntu/app.log"

# Download JAR from S3 (uploaded manually beforehand)
$AWS_CLI s3 cp s3://${app_bucket_name}/app.jar $APP_PATH --region ap-south-1

# Run the app on port 80
nohup java -jar $APP_PATH --server.port=80 > $APP_LOG 2>&1 &


cat <<'EOL' > /usr/local/bin/poll_app.sh
#!/bin/bash
APP_PATH="/home/ubuntu/app.jar"
APP_LOG="/home/ubuntu/app.log"
S3_BUCKET="${app_bucket_name}"
AWS_CLI=/usr/local/bin/aws

while true; do
    # Last modified timestamp in S3
    S3_MODIFIED=$($AWS_CLI s3api head-object --bucket $S3_BUCKET --key app.jar --query "LastModified" --output text --region ap-south-1)

    # Local timestamp
    if [ -f "$APP_PATH" ]; then
        LOCAL_MODIFIED=$(date -r $APP_PATH -u +"%Y-%m-%dT%H:%M:%SZ")
    else
        LOCAL_MODIFIED=""
    fi

    if [ "$S3_MODIFIED" != "$LOCAL_MODIFIED" ]; then
        echo "New JAR detected, updating..."

        # Kill old app
        pkill -f "java -jar $APP_PATH"

        # Download and restart
        $AWS_CLI s3 cp s3://$S3_BUCKET/app.jar $APP_PATH --region ap-south-1
        nohup java -jar $APP_PATH --server.port=80 > $APP_LOG 2>&1 &
    fi

    sleep 60
done
EOL

chmod +x /usr/local/bin/poll_app.sh
nohup /usr/local/bin/poll_app.sh > /home/ubuntu/poll.log 2>&1 &


cat <<EOL > /usr/local/bin/shutdown_upload.sh
#!/bin/bash
$AWS_CLI s3 cp /var/log/cloud-init.log s3://${bucket_name}/ec2-logs/ --region ap-south-1
$AWS_CLI s3 cp /home/ubuntu/app.log s3://${bucket_name}/app/logs/ --region ap-south-1
EOL

chmod +x /usr/local/bin/shutdown_upload.sh

# Systemd service to run shutdown upload
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

cat <<EOL > /etc/systemd/system/poll-app.service
[Unit]
Description=Poll S3 for new JAR and restart app
After=network.target

[Service]
ExecStart=/usr/local/bin/poll_app.sh
Restart=always
User=ubuntu

[Install]
WantedBy=multi-user.target
EOL

# Enable shutdown service
systemctl enable upload-logs.service
systemctl enable poll-app.service
systemctl start poll-app.service