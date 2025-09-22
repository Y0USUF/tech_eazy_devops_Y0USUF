# tech_eazy_devops_Y0USUF
# 🚀 DevOps Terraform Project – Spring MVC App Deployment on AWS EC2

This project demonstrates **Lift & Shift deployment** of a Java Spring MVC application onto an **AWS EC2 instance** using **Terraform** and **User Data automation**.

---

## 📂 Project Structure

```
.
├── terraform/
│   ├── main.tf           # Terraform configuration (provider, EC2, SG)
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Outputs (public IP)
│   └── .terraform.lock.hcl
│
├── scripts/
│   └── user_data.sh      # Bootstrap script to install dependencies, build & run app
│
├── LICENSE.txt           # MPL 2.0 License
└── README.md             # Project documentation
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

Logs are stored at:

```bash
/home/ubuntu/app.log
```

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
