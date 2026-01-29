data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  owners = ["amazon"]
}

resource "aws_iam_role" "ec2" {
  name = "asg-ec2-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "asg-instance-profile-${var.environment}"
  role = aws_iam_role.ec2.name
}

resource "aws_security_group" "app" {
  name   = "app-sg-${var.environment}"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg"
  }
}

locals {
  user_data = <<-EOF
              #!/bin/bash
              set -e
              dnf update -y
              dnf install -y nginx
              systemctl enable nginx
              systemctl start nginx

              INSTANCE_ID=$(curl -s --fail http://169.254.169.254/latest/meta-data/instance-id || echo "unknown")

              cat <<HTML > /usr/share/nginx/html/index.html
              <html>
              <body>
              <h1>Terraform ASG</h1>
              <p>Instance ID: $INSTANCE_ID</p>
              </body>
              </html>
              HTML
              EOF
}

resource "aws_launch_template" "app" {
  name_prefix   = "app-lt-${var.environment}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }

  user_data = base64encode(local.user_data)

  metadata_options {
    http_tokens = "required"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "app-instance"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "app-asg-${var.environment}"
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  vpc_zone_identifier       = var.private_subnet_ids
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
