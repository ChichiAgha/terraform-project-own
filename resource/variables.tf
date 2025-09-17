variable "public_instances" {
  description = "Map of public EC2 instance configs for for_each"
  type = map(object({
    ami           = string
    instance_type = string
    name          = string
  }))
  default = {}
}

variable "private_instance_count" {
  description = "Number of private EC2 instances to create with count"
  type        = number
  default     = 1
}

variable "private_ami" {
  description = "AMI for private EC2 instances"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
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
  default = {}
}
