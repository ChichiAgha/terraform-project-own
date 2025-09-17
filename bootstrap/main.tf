#bootstrap/main.tf (uses local backend by default)
provider "aws" {
  region = "eu-west-2" # change this to your region
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "tf_state" {
  bucket = "my-terraform-state-bucket-12345-golder" # must be globally unique
}

# Enable versioning (recommended for safety)
resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "tf_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# IAM role for Lambda
/*resource "aws_iam_role" "lambda_ami_cleanup" {
  name = "lambda_ami_cleanup_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM policy for Lambda to deregister AMI
resource "aws_iam_role_policy" "lambda_ami_cleanup_policy" {
  name = "lambda_ami_cleanup_policy"
  role = aws_iam_role.lambda_ami_cleanup.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DeregisterImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function to deregister AMI
resource "aws_lambda_function" "ami_cleanup" {
  filename         = "lambda_ami_cleanup.zip" # Upload this zip file with your Python code
  function_name    = "ami_cleanup"
  role             = aws_iam_role.lambda_ami_cleanup.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("lambda_ami_cleanup.zip")
  timeout          = 30
  environment {
    variables = {
      AMI_ID = "ami-xxxxxxxxxxxxxxxxx" # Set your AMI ID here or pass as event
    }
  }
}*/