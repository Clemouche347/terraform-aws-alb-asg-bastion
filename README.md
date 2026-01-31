# AWS Production Infrastructure - ALB + ASG + Bastion

Production-grade AWS infrastructure using Terraform with Auto Scaling, Application Load Balancer, and secure bastion access.

## Architecture

- **VPC**: Multi-AZ setup with public and private subnets
- **Bastion Host**: Secure jump server in public subnet with SSM support
- **Auto Scaling Group**: Application tier in private subnets
- **Application Load Balancer**: (Coming in Week 5 Day 3)

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- Valid AWS credentials
- SSH key pair created in AWS

## Quick Start

1. Navigate to environment:
```bash
   cd envs/dev
```

2. Create `terraform.tfvars`:
```hcl
   vpc_id             = "vpc-xxxxx"
   public_subnet_id   = "subnet-xxxxx"
   private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
   allowed_ssh_cidr   = "YOUR_IP/32"
   key_name           = "your-key-name"
   region             = "eu-west-3"
```

3. Deploy:
```bash
   terraform init
   terraform plan
   terraform apply
```

## Security Features

- ✅ IMDSv2 enforced on all EC2 instances
- ✅ SSH restricted to specific IP
- ✅ SSM Session Manager enabled
- ✅ Private instances have no public IPs
- ✅ Security groups follow least-privilege

