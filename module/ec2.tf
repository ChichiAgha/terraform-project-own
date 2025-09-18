## EBS Volumes using for_each (demonstrates for_each on a different resource)
resource "aws_ebs_volume" "extra" {
  for_each          = var.ebs_volumes
  availability_zone = each.value.az
  size              = each.value.size
  encrypted         = true
  kms_key_id        = aws_kms_key.ebs_key.arn
  tags = {
    Name = each.value.name
  }
}

provider "aws" {
  region = var.region
}

locals {
  ec2_names = ["web", "app"]
  ec2_matrix = flatten([
    for name in local.ec2_names : [
      for i in range(2) : {
        name  = name
        index = i + 1
      }
    ]
  ])
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name = "/aws/vpc/flow-logs/main"
  retention_in_days = 365
  kms_key_id = aws_kms_key.cloudwatch_logs_key.arn
}

resource "aws_flow_log" "main_vpc_flow_log" {
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  vpc_id         = aws_vpc.main.id
  traffic_type   = "ALL"
  iam_role_arn   = aws_iam_role.vpc_flow_logs.arn
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "vpc-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_default_security_group" "main_vpc_default" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = []
    description = "No ingress allowed"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = []
    description = "No egress allowed"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[0]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "private-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "Allow HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    description = "Allow all outbound traffic to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  tags = {
    Name = "ec2-sg"
  }
}

# Data source for AZs
data "aws_availability_zones" "available" {}

# EC2 in Public Subnet
## Public EC2 instances using for_each (map/object for different configs)
resource "aws_instance" "public" {
  for_each                    = var.public_instances
  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = false
  monitoring                  = true
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
  }
  root_block_device {
    encrypted   = true
    kms_key_id  = aws_kms_key.ebs_key.arn
  }
  tags = {
    Name = each.value.name
  }
  lifecycle {
    prevent_destroy = false
  }
}

# EC2 in Private Subnet
## Private EC2 instances using count (identical resources)
resource "aws_instance" "private" {
  count                       = var.private_instance_count
  ami                         = var.private_ami
  instance_type               = var.private_instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = false
  tags = {
    Name = "private-${count.index + 1}"
  }
    monitoring                  = true
    ebs_optimized               = true
    iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
    root_block_device {
      encrypted = true
      kms_key_id = aws_kms_key.ebs_key.arn
    }
    metadata_options {
      http_tokens = "required"
      http_endpoint = "enabled"
    }
    depends_on = [aws_instance.public]
}

  # IAM role for EC2 instance profile
  resource "aws_iam_role" "ec2_instance_role" {
    name = "ec2-instance-role"
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }]
    })
  }

  resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2-instance-profile"
    role = aws_iam_role.ec2_instance_role.name
  }