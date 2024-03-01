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
  secret_key = "***"
}
resource "aws_vpc" "main" {
 cidr_block = "192.169.0.0/16"
 
 tags = {
   Name = "Terraform VPC"
 }
}
resource "aws_subnet" "public_subnets" {
 count      = length(var.public_subnet_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.public_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index) 
 tags = {
   Name = "Public Subnet ${count.index + 1}"
 }
}
 
resource "aws_subnet" "private_subnets" {
 count      = length(var.private_subnet_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.private_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 tags = {
   Name = "Private Subnet ${count.index + 1}"
 }
}
resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.main.id
 
 tags = {
   Name = "Project VPC IG"
 }
}
resource "aws_route_table" "second_rt" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "2nd Route Table"
 }
}
resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_subnet_cidrs)
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.second_rt.id
}
# Create the Security Group
resource "aws_security_group" "My_TERRA_VPC_Security_Group" {
  vpc_id       = aws_vpc.main.id
  name         = "My TERRA_VPC Security Group"
  description  = "My VPC Security Group"
  
  # allow ingress of port 22
  ingress {
    cidr_blocks = var.ingressCIDRblock 
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  } 
  ingress {
    cidr_blocks = var.ingressCIDRblock
    from_port  = 80
    to_port    = 80
    protocol    = "tcp"
  }
  
  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
   Name = "My TERRA_VPC Security Group"
   Description = "My VPC Security Group"
}
}
##EC2 LAUNCH IN THIS NEW VPC####
resource "aws_instance" "web" {
  count = var.numberofserver
  ami = var.ami
  #subnet_id = var.subnet_id
  subnet_id = element(aws_subnet.public_subnets[*].id, count.index)
  key_name = var.key_name
  security_groups = ["${aws_security_group.My_TERRA_VPC_Security_Group.id}"]
  instance_type = var.instancetype
  associate_public_ip_address = "true"
  ##USER DATA
  user_data = <<EOF
    #! /bin/bash
    sudo su
    sudo yum update
    sudo yum install -y httpd
    sudo chkconfig httpd on
    sudo service httpd start
    echo "<h1>Hey,successfully Deployed EC2 With Terraform</h1>" | sudo tee /var/www/html/index.html
    EOF
  tags = {
    Name = "Terraform-01"
  }
}
###LB CREATE####
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "front" {
  name     = "application-front"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    matcher             = 200
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 3
    unhealthy_threshold = 2
  }
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment
resource "aws_lb_target_group_attachment" "attach-app1" {
  count            = 2
  target_group_arn = aws_lb_target_group.front.arn
  target_id        = element(aws_instance.web.*.id, count.index)
  port             = 80
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front.arn
  }
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "front" {
  name               = "front"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.My_TERRA_VPC_Security_Group.id}"]
  subnets            = [for subnet in aws_subnet.public_subnets: subnet.id]

  enable_deletion_protection = false

  tags = {
    Environment = "front"
  }
}
