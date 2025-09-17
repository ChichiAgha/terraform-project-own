variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
}


variable "dynamodb_table" {
  description = "DynamoDB table for state locking"
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ec2_ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

/*variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
}

variable "lambda_handler" {
  description = "Lambda handler"
  type        = string
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
}
*/