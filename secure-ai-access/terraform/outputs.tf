output "postgres_private_ip" {
  description = "Private IP of the PostgreSQL instance (use in SIA target config)"
  value       = aws_instance.postgres.private_ip
}

output "postgres_public_ip" {
  description = "Public IP of the PostgreSQL instance (SSH access)"
  value       = aws_instance.postgres.public_ip
}

output "postgres_instance_id" {
  description = "PostgreSQL EC2 instance ID"
  value       = aws_instance.postgres.id
}

output "connector_private_ip" {
  description = "Private IP of the SIA Connector"
  value       = aws_instance.sia_connector.private_ip
}

output "connector_public_ip" {
  description = "Public IP of the SIA Connector (SSH access)"
  value       = aws_instance.sia_connector.public_ip
}

output "connector_instance_id" {
  description = "SIA Connector EC2 instance ID"
  value       = aws_instance.sia_connector.id
}
