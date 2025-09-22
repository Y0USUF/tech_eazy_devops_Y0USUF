#!/bin/bash
sudo apt update -y
sudo apt install -y openjdk-21-jdk maven git

# Clone repo
cd /home/ubuntu
git clone https://github.com/Trainings-TechEazy/test-repo-for-devops.git
cd test-repo-for-devops

# Build project
mvn clean package

# Run app on 80
sudo nohup java -jar target/hellomvc-0.0.1-SNAPSHOT.jar --server.port=80 > /home/ubuntu/app.log 2>&1 &
