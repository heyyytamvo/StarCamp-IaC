output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = { for subnet in aws_subnet.public_subnet : subnet.id => subnet.tags["Name"] }
}