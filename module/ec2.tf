## EBS Volumes using for_each (demonstrates for_each on a different resource)
resource "aws_ebs_volume" "extra" {
  for_each = var.ebs_volumes
  availability_zone = each.value.az
  size              = each.value.size
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
        name = name
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

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[0]
  map_public_ip_on_launch = true
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
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
  for_each      = var.public_instances
  ami           = each.value.ami
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
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
  count         = var.private_instance_count
  ami           = var.private_ami
  instance_type = var.private_instance_type
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = false
  tags = {
    Name = "private-${count.index + 1}"
  }
  lifecycle {
    prevent_destroy = true
  }
  depends_on = [aws_instance.public]
}