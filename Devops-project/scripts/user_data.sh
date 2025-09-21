#!/bin/bash

# Exit on any error
set -e

# Log everything for debugging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting user data script execution at $(date)"

# Update system and install dependencies
echo "Updating system packages..."
sudo apt update -y
sudo apt install -y openjdk-21-jdk maven git curl

# Verify installations
echo "Verifying installations..."
java -version
mvn -version
git --version

# Create application directory
echo "Setting up application directory..."
cd /home/ubuntu
rm -rf app  # Clean up any existing installation
git clone https://github.com/Trainings-TechEazy/test-repo-for-devops.git app
cd app

# Patch controllers to return plain text instead of views
echo "Patching Spring controllers..."
if [ -d "src/main/java/com/example/hellomvc/controller" ]; then
    sed -i 's/@Controller/@RestController/g' src/main/java/com/example/hellomvc/controller/*.java
    sed -i 's/(Model model)//g' src/main/java/com/example/hellomvc/controller/*.java
    sed -i 's/, Model model//g' src/main/java/com/example/hellomvc/controller/*.java
    echo "Controllers patched successfully"
else
    echo "Warning: Controller directory not found, skipping patching"
fi

# Build project (skip tests for faster build)
echo "Building Maven project..."
mvn clean package -DskipTests

# Verify build was successful
if [ ! -d "target" ] || [ -z "$(ls target/*.jar 2>/dev/null | grep -v 'original')" ]; then
    echo "Error: Build failed - no JAR file found"
    exit 1
fi

# Find the built JAR dynamically
JAR_FILE=$(ls target/*.jar | grep -v 'original' | head -n 1)
echo "Found JAR file: $JAR_FILE"

# Create a systemd service for better process management
echo "Creating systemd service..."
sudo tee /etc/systemd/system/springboot-app.service > /dev/null <<EOF
[Unit]
Description=Spring Boot Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/app
ExecStart=/usr/bin/java -jar $JAR_FILE
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable springboot-app.service
sudo systemctl start springboot-app.service

# Wait a moment and check if service is running
sleep 10
if sudo systemctl is-active --quiet springboot-app.service; then
    echo "Application started successfully"
    echo "Service status:"
    sudo systemctl status springboot-app.service --no-pager
else
    echo "Warning: Service may not have started properly"
    sudo systemctl status springboot-app.service --no-pager
fi

# Create a simple health check endpoint verification
echo "Waiting for application to be ready..."
for i in {1..30}; do
    if curl -f http://localhost:8080/actuator/health 2>/dev/null || curl -f http://localhost:8080/ 2>/dev/null; then
        echo "Application is responding on port 8080"
        break
    fi
    echo "Waiting for application... (attempt $i/30)"
    sleep 10
done

echo "User data script completed at $(date)"