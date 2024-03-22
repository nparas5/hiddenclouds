# Define provider
provider "aws" {
  region = "ap-southeast-1" # Change this to your desired region
}

# IAM Role and Instance Profile for S3 access and SSM access
resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-ssm-access-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "ec2.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-ssm-access-profile"
  role = aws_iam_role.ec2_role.name
}

# Attach AWS managed policies to the IAM role
resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "s3_full_access_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_read_only_access_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_full_access_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Declare the security group for EC2 instances
resource "aws_security_group" "server_sg" {
  name        = "server-security-group"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Allow traffic from ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow outbound traffic to anywhere
  }
}

# Autoscaling Group
resource "aws_launch_configuration" "server_launch_config" {
  name_prefix          = "server-launch-config-"
  image_id             = "ami-06d31f9769687680d" # Amazon Linux 2 AMI for SINGAPORE REGION
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.server_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = <<-BASH
              #!/bin/bash
              yum update -y
              yum install -y nginx
              systemctl start nginx
              systemctl enable nginx
              aws s3 cp s3://nginxweb1x2x3x/index.html /usr/share/nginx/html/index.html
              systemctl restart nginx
              BASH
}

resource "aws_autoscaling_group" "server_autoscaling_group" {
  name                 = "server-autoscaling-group"
  launch_configuration = aws_launch_configuration.server_launch_config.id
  min_size             = 3
  max_size             = 3
  desired_capacity     = 3
  vpc_zone_identifier  = var.private_subnet_ids
}

# Public Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-sg-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Adding an outbound rule to allow traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "public_alb" {
  name               = "public-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids # Corrected reference
  security_groups    = [aws_security_group.alb_sg.id]
}

# Target Group
resource "aws_lb_target_group" "server_target_group" {
  name        = "server-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    timeout             = 5
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ALB Listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server_target_group.arn
  }
}

# Output
output "server_autoscaling_group_name" {
  value = aws_autoscaling_group.server_autoscaling_group.name
}

output "public_alb_dns_name" {
  value = aws_lb.public_alb.dns_name
}
