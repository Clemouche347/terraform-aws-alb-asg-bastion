# AWS Production Infrastructure - ALB + ASG + Bastion

Production-grade AWS infrastructure using Terraform with Auto Scaling, Application Load Balancer, and secure bastion access.

## Architecture Overview

```
                         INTERNET
                            │
            ┌───────────────┼───────────────┐
            │               │               │
            ▼               ▼               │
      ┌──────────┐   ┌──────────┐   ┌─────────┐
      │ Bastion  │   │   ALB    │──▶│   S3    │
      │ (SSH:22) │   │ (HTTP:80)│   │  Logs   │
      └──────────┘   └────┬─────┘   └─────────┘
            │             │                │
            │      ┌──────┴──────┐         │
            │      ▼             ▼         │
            │  ┌───────┐    ┌───────┐      │
            └─▶│ EC2   │    │ EC2   │      │
               │ nginx │    │ nginx │      │
               └───────┘    └───────┘      │
                   PRIVATE SUBNETS         │
```

### Components

| Component | Location | Purpose |
|-----------|----------|---------|
| **ALB** | Public subnets (2 AZs) | Distributes HTTP traffic, health checks |
| **ASG** | Private subnets (2 AZs) | Auto-scaling application instances (1-3) |
| **Bastion** | Public subnet | SSH jump host for admin access |
| **S3 Logs** | Regional | ALB access logs with lifecycle management |

## Project Structure

```
terraform-aws-alb-asg-bastion/
├── modules/
│   ├── alb/           # Application Load Balancer
│   ├── asg/           # Auto Scaling Group
│   ├── bastion/       # Bastion Host
│   └── observability/ # ALB Access Logs (S3)
└── envs/
    └── dev/           # Development environment
```

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- Valid AWS credentials
- SSH key pair created in AWS
- Existing VPC with public and private subnets

## Quick Start

1. Navigate to environment:
```bash
cd envs/dev
```

2. Create `terraform.tfvars`:
```hcl
vpc_id             = "vpc-xxxxx"
public_subnet_ids  = ["subnet-xxxxx", "subnet-yyyyy"]
private_subnet_ids = ["subnet-aaaaa", "subnet-bbbbb"]
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

4. Access the application:
```bash
# Get the ALB DNS name from outputs
curl http://<alb_dns_name>
```

## Modules

### ALB Module

Creates an internet-facing Application Load Balancer with:
- HTTP listener on port 80
- Target group with health checks
- Security group allowing HTTP from anywhere

### ASG Module

Creates an Auto Scaling Group with:
- Launch template (Amazon Linux 2023, nginx)
- Scaling: min=1, desired=2, max=3
- ELB health checks
- SSM Session Manager access

### Bastion Module

Creates a jump host with:
- Public IP in public subnet
- SSH access restricted to specified CIDR
- SSM Session Manager as alternative access

### Observability Module

Creates S3 bucket for ALB access logs with:
- Lifecycle policy: Standard → IA (30d) → Glacier (90d) → Delete (180d)
- Versioning enabled for data protection
- Public access blocked
- Bucket policy for ALB log delivery

## Security Features

- IMDSv2 enforced on all EC2 instances
- SSH restricted to specific IP (bastion only)
- SSM Session Manager enabled (no SSH keys for ASG)
- Private instances have no public IPs
- Security group chaining (ASG accepts traffic only from ALB)

## Accessing Instances

### Via Bastion (SSH)
```bash
ssh -i your-key.pem ec2-user@<bastion_public_ip>
```

### Via SSM Session Manager
```bash
aws ssm start-session --target <instance_id>
```

## Outputs

| Output | Description |
|--------|-------------|
| `bastion_public_ip` | Public IP of bastion host |
| `bastion_instance_id` | Instance ID for SSM access |
| `asg_name` | Auto Scaling Group name |
| `alb_dns_name` | DNS name to access the application |
| `alb_logs_bucket_name` | S3 bucket name for ALB access logs |
| `alb_logs_bucket_arn` | S3 bucket ARN for ALB access logs |

## Customization

Override defaults in `terraform.tfvars`:

```hcl
# Scaling
desired_capacity = 2
min_size         = 1
max_size         = 5

# Environment
environment = "staging"
```

