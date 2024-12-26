terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region     = "ap-south-1"
  access_key = "****"
  secret_key = "****"
}

resource "aws_launch_template" "example" {
  name                = "Terraform-launch-template"
  image_id            = var.ami  # Replace with your desired AMI ID
  instance_type       = var.instancetype  # Choose the instance type you need
  key_name            = var.key_name  # Replace with your EC2 key pair name
  #security_group_names = [var.security_group_id] # Replace with the desired security group names
 network_interfaces {
    security_groups = [var.security_group_id]  # Correct reference to security group name
  }
  # Optional: You can set tags for the Launch Template
  tags ={
    Name  = "My_Template"
    key   = "Environment"
    value = "Development"
  }

  # Optional: Add block device mapping (e.g., EBS volumes)
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8  # Size in GiB
      volume_type = "gp3"
      delete_on_termination = true
    }
  }

  # Optional: Specify user data script (e.g., for configuring the instance at launch)
  user_data = base64encode(var.user_data_script)
  # Optional: Set a spot price (only relevant if you're using Spot instances)
  # spot_price = "0.015"

  # Optional: Enable monitoring (CloudWatch)
  
  monitoring {
    enabled = false
  }

  # Optional: Enable Instance Metadata Service v2 (IMDSv2)
  metadata_options {
    http_tokens = "required"
  }
  # Enable versioning (new versions will be created with each change)
  lifecycle {
    create_before_destroy = true
  }
}

output "launch_template_id" {
  value = aws_launch_template.example.id
}

# asg.tf
resource "aws_autoscaling_group" "example_asg" {
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-id"]

  # Use Launch Template
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"  # You can also specify a particular version, e.g., "1"
  }

  health_check_type          = "EC2"
  health_check_grace_period = 300
  wait_for_capacity_timeout   = "0"

  # Tags
  tag {
    key                 = "Name"
    value               = "ASG-Instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  # Optional: Load balancer association (if you have an ELB)
  ###load_balancers = []  # Add your load balancer name if needed
}
