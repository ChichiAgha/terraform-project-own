variable "public_instances" {
  description = "Map of public EC2 instance configs for for_each"
  type = map(object({
    ami           = string
    instance_type = string
    name          = string
  }))
}

variable "private_instance_count" {
  description = "Number of private EC2 instances to create with count"
  type        = number
  default     = 1
}

variable "private_ami" {
  description = "AMI for private EC2 instances"
  type        = string
}

variable "private_instance_type" {
  description = "Instance type for private EC2 instances"
  type        = string
  default     = "t2.micro"
}

variable "ebs_volumes" {
  description = "Map of EBS volume configs for for_each"
  type = map(object({
    az   = string
    size = number
    name = string
  }))
}
variable "ec2_config" {
  type = object({
    name_prefix    = string
    instance_count = number
    instance_type  = string
  })
  default = {
    name_prefix    = "web"
    instance_count = 2
    instance_type  = "t2.micro"
  }
}
