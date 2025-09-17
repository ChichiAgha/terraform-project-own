#bootstrap/main.tf (uses local backend by default)
provider "aws" {
  region = "eu-west-2" # change this to your region
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "tf_state" {
  bucket = "my-terraform-state-bucket-12345-golder" # must be globally unique

  # Enable server-side encryption with KMS
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3_bucket_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  # Enable access logging
  logging {
    target_bucket = aws_s3_bucket.tf_state_logs.id
    target_prefix = "log/"
  }

  # Enable event notifications (example: for object creation)
  notification {
    topic {
      topic_arn = aws_sns_topic.s3_events.arn
      events    = ["s3:ObjectCreated:*"]
    }
  }

  # Enable public access block
  public_access_block {
    block_public_acls   = true
    block_public_policy = true
    ignore_public_acls  = true
    restrict_public_buckets = true
  }

  # Enable lifecycle configuration (example: delete after 365 days)
  lifecycle_rule {
    id      = "expire-objects"
    enabled = true
    expiration {
      days = 365
    }
  }

  # Enable cross-region replication (example)
  replication_configuration {
    role = aws_iam_role.s3_replication.arn
    rules {
      id     = "replicate-all"
      status = "Enabled"
      destination {
        bucket        = aws_s3_bucket.tf_state_replica.arn
        storage_class = "STANDARD"
      }
      filter {}
    }
  }
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

  point_in_time_recovery {
    enabled = true
  }
}

    server_side_encryption {
      enabled     = true
      kms_key_arn = aws_kms_key.dynamodb_table_key.arn
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

      resource "aws_s3_bucket_notification" "tf_state_events" {
        bucket = aws_s3_bucket.tf_state.id
        topic {
          topic_arn = aws_sns_topic.s3_events.arn
          events    = ["s3:ObjectCreated:*"]
        }
      }

      resource "aws_s3_bucket_public_access_block" "tf_state_block" {
        bucket                  = aws_s3_bucket.tf_state.id
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
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