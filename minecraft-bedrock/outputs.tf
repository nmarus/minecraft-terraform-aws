output "name" {
  description = "Value of the name of the instance"
  value       = local.name
}

output "ec2" {
  description = "EC2 instance"
  value       = module.ec2
}

output "public_ip" {
  description = "Value of the public IP address of the instance"
  value       = aws_eip.this.public_ip
}

output "public_dns" {
  description = "Value of the public DNS name of the instance"
  value       = aws_eip.this.public_dns
}

output "aws_key_pair" {
  description = "Value of the AWS key pair"
  value       = aws_key_pair.this
}

output "tls_private_key" {
  description = "Value of the TLS private key"
  value       = tls_private_key.this
}
