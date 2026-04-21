![architecture](/assets/diagram.png)

# Serverless Weather Application (AWS + Terraform)

A highly secure, multi-tier weather search application built with **FastAPI** and **Vanilla JS**, deployed on **AWS** using **Terraform (IaC)**. This project demonstrates a "Zero Trust" architecture, where the backend is entirely private and accessible only through a secure CloudFront gateway.

## 🏗 Architecture Overview

The infrastructure follows AWS best practices for security and high availability across multiple Availability Zones (AZs).

### Core Components:
- **Edge Layer:** **Route 53** for DNS and **CloudFront** as a CDN/Security Proxy.
- **Frontend:** Static site hosted on **S3** with **Origin Access Control (OAC)**.
- **API/Backend:** **FastAPI** running on **AWS ECS Fargate** (Serverless Compute).
- **Networking:** **VPC** with Public and Private Subnets across 2 AZs.
- **Security:** **Application Load Balancer (ALB)** with custom header validation and **SSM Parameter Store** for secret management.



## 🔒 Security Features (The "Zero Trust" Model)

1. **Private Backend:** The ECS tasks live in **Private Subnets** with no public IP addresses. They cannot be reached directly from the internet.
2. **Cloaked API:** The API is "cloaked" behind the main domain (`yashjagani.com/api`). Direct access to the ALB via `api.yashjagani.com` is blocked.
3. **Header Verification:** CloudFront injects a **Shared Secret Header** into every request. The ALB rejects any request missing this header with a **403 Forbidden**.
4. **Least Privilege:** Security Groups are strictly scoped. The ECS tasks only accept traffic from the ALB on port 8000.
5. **SSL/TLS:** End-to-end encryption using **AWS Certificate Manager (ACM)**.

## 🚀 Deployment Workflow

This project is fully automated via Terraform and custom shell scripts.

### Prerequisites
- AWS CLI configured
- Terraform installed
- Docker installed

### 1. Infrastructure Setup
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

### 2. Backend Deployment
The backend deployment is handled by a script that builds the Docker image, pushes it to ECR, and triggers a rolling update on ECS:
```bash
./push_image.sh
```

### 3. Frontend Deployment
Synchronizes the local frontend assets to the S3 bucket and invalidates the CloudFront cache:
```bash
./sync_s3.sh
```

### Tech Stack
**Infrastructure**: Terraform (HCL), AWS (VPC, ECS, S3, CloudFront, ALB, Route 53)\
**Backend**: Python, FastAPI, Docker\
**Frontend**: HTML5, CSS3, JavaScript (Fetch API)\
**Secrets**: AWS SSM Parameter Store