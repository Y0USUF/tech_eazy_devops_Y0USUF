# tech_eazy_devops_Y0USUF
# 🚀 DevOps Terraform Project – Spring MVC App Deployment on AWS EC2

This demonstrates **Lift & Shift deployment** of a Java Spring MVC application onto an **AWS EC2 instance** using **Terraform** and **User Data automation**.
This project extends the previous Spring MVC Lift & Shift deployment to include S3 automation and IAM roles.
---

## 📂 Project Structure

```
.
terraform/
├── main.tf              # EC2 + IAM role attachment + bucket
├── variables.tf         # Bucket name, region, instance type
├── outputs.tf           # Public IP, bucket name
├── iam.tf               # IAM roles, policies, instance profiles
├── s3.tf                # S3 bucket + lifecycle rules
scripts/
├── user_data.sh         # App setup
├── shutdown_upload.sh   # Upload logs to S3 on shutdown
```

---
⚠️ Note: Ensure you have an existing AWS key pair (e.g., my-keypair) created in your region. Update the variables.tf file with your key pair name. The .pem file should be kept safe locally and never committed to GitHub.
## ⚙️ Prerequisites

Before you begin, ensure you have the following installed on your local machine:

* [Terraform](https://developer.hashicorp.com/terraform/downloads)
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* AWS account credentials configured (`aws configure`)
* An **AWS Key Pair** (e.g., `my-key.pem`) already created in the target region

---

## 🚀 Deployment Steps

### 1. Clone this repository

```bash
git clone <your-repo-url>
cd devops-project/terraform
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Validate & Plan

```bash
terraform plan
```

### 4. Apply (Provision Resources)

```bash
terraform apply -auto-approve
```

### 5. Get Public IP

```bash
terraform output instance_public_ip
terraform output bucket_name
```

### 6. Access Application

Open in browser:

```
http://<EC2_PUBLIC_IP>/hello
http://<EC2_PUBLIC_IP>/parcel
```

---

## 🖥️ What Happens Inside EC2

The `user_data.sh` script runs automatically at instance launch:

1. Updates system packages
2. Installs Java (OpenJDK 21), Maven, Git
3. Clones the demo Spring MVC repo
4. Builds the JAR using Maven
5. Starts the app on **port 80** using `nohup`

upload_logs.sh – Runs at shutdown (cloud-init or systemd shutdown script):

Uploads EC2 logs (/var/log/cloud-init.log) to S3

Uploads Spring MVC app logs to s3://techeazy-ec2logs/app/logs
Logs are stored at:

```bash
/home/ubuntu/app.log
```
---
🚀 Workflow

Terraform applies → provisions EC2 + IAM roles + S3 bucket.

EC2 launches → user_data.sh runs app, writes logs.

On shutdown → shutdown_upload.sh uploads logs to S3.

Lifecycle policy auto-deletes logs after 7 days.

Role A can only list S3 contents → used for verification.

---
🔒 Security and IAM

Role A – S3 ReadOnly

Role B – Create bucket & upload only

Instance Profile – Attaches Role B to EC2

Terraform automatically handles Security Group for SSH (22) and HTTP (80)

---

## 🔒 Security Group Configuration

Terraform automatically provisions a Security Group that:

* Allows **SSH (22)** from anywhere
* Allows **HTTP (80)** from anywhere

---

## 🧹 Cleanup

To avoid unnecessary AWS costs, destroy resources when done:

```bash
terraform destroy -auto-approve
```
