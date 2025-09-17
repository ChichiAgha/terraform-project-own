locals {
  ec2_instance_type = "dev" == "prod" ? "t3.micro" : "t2.micro"
}

terraform {
  backend "s3" {
    bucket  = "my-terraform-state-bucket-12345-golder"
    key     = "develop/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
  }
}

module "my_ec2" {
  source                 = "../module"
  environment            = "dev" # or "prod"
  region                 = "eu-west-2"
  vpc_cidr               = "10.0.0.0/16"
  public_subnet_cidrs    = ["10.0.1.0/24"] # add more if needed
  private_subnet_cidr    = "10.0.2.0/24"
  dynamodb_table         = "terraform-locks"
  ec2_instance_type      = local.ec2_instance_type
  ec2_ami_id             = "ami-046c2381f11878233"
  public_instances       = var.public_instances
  private_instance_count = var.private_instance_count
  private_ami            = var.private_ami
  private_instance_type  = var.private_instance_type
  ebs_volumes            = var.ebs_volumes
}