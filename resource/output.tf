
output "ec2_instance_ids" {
	description = "IDs of created EC2 instances"
		value = module.my_ec2.public_instance_ids
}

output "private_instance_ids" {
	description = "IDs of private EC2 instances"
	value = module.my_ec2.private_instance_ids
}

output "ebs_volume_ids" {
	description = "IDs of created EBS volumes"
	value = module.my_ec2.ebs_volume_ids
}
