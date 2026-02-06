# AWS Production Infrastructure - ALB + ASG + Bastion + Observability

Production-grade AWS infrastructure using Terraform with Auto Scaling, Application Load Balancer, secure bastion access, and CloudWatch monitoring.

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
            │             │
            │      ┌──────┴──────┐     ┌────────────────┐
            │      ▼             ▼     │  CloudWatch    │
            │  ┌───────┐    ┌───────┐  │  - Dashboard   │
            └─▶│ EC2   │    │ EC2   │  │  - Alarms      │
               │ nginx │    │ nginx │  │  - SNS Alerts  │
               └───────┘    └───────┘  └────────────────┘
                   PRIVATE SUBNETS
```

### Components

| Component | Location | Purpose |
|-----------|----------|---------|
| **ALB** | Public subnets (2 AZs) | Distributes HTTP traffic, health checks |
| **ASG** | Private subnets (2 AZs) | Auto-scaling application instances (1-3) |
| **Bastion** | Public subnet | SSH jump host for admin access |
| **Observability** | Regional | CloudWatch alarms, dashboard, S3 logs, SNS notifications |

## Project Structure

```
terraform-aws-alb-asg-bastion/
├── modules/
│   ├── alb/           # Application Load Balancer
│   ├── asg/           # Auto Scaling Group
│   ├── bastion/       # Bastion Host
│   └── observability/ # CloudWatch monitoring, S3 logs, SNS alerts
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
vpc_id                = "vpc-xxxxx"
public_subnet_ids     = ["subnet-xxxxx", "subnet-yyyyy"]
private_subnet_ids    = ["subnet-aaaaa", "subnet-bbbbb"]
allowed_ssh_cidr      = "YOUR_IP/32"
key_name              = "your-key-name"
region                = "eu-west-3"
alarm_email_endpoints = ["your-email@example.com"]
```

3. Deploy:
```bash
terraform init
terraform plan
terraform apply
```

> **Note:** On first deploy, the bastion instance ID is unknown at plan time. Use a two-step apply:
> ```bash
> terraform apply -target=module.bastion
> terraform apply
> ```

4. Access the application:
```bash
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
- EC2 health checks (configurable to ELB when app is deployed)
- SSM Session Manager access

### Bastion Module

Creates a jump host with:
- Public IP in public subnet
- SSH access restricted to specified CIDR
- SSM Session Manager as alternative access

### Observability Module

Provides full monitoring and logging:

**CloudWatch Dashboard** with widgets for:
- ASG capacity and instance lifecycle metrics
- EC2 CPU utilization per instance
- ALB request count, response time, HTTP codes, target health (when enabled)

**CloudWatch Alarms:**
- ASG high CPU utilization
- ASG no healthy instances
- EC2 high CPU per instance
- EC2 status check failures
- ALB unhealthy targets, high response time, 5xx error rate (when enabled)

**SNS Notifications:**
- Email alerts on alarm state changes
- Configurable OK notifications on recovery

**S3 Access Logs:**
- ALB access logs with lifecycle policy: Standard -> IA (30d) -> Glacier (90d) -> Delete (180d)
- Versioning enabled, public access blocked

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

# Alarm thresholds
cpu_threshold              = 80
response_time_threshold    = 2.0
error_5xx_threshold        = 5.0

# Environment
environment = "staging"
```

