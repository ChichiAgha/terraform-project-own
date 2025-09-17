output "public_instance_ids" {
  description = "IDs of public EC2 instances"
  value       = [for instance in aws_instance.public : instance.id]
}

output "private_instance_ids" {
  description = "IDs of private EC2 instances"
  value       = [for instance in aws_instance.private : instance.id]
}

output "ebs_volume_ids" {
  description = "IDs of created EBS volumes"
  value       = [for vol in aws_ebs_volume.extra : vol.id]
}
