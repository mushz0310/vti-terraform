output "private_key" {
  value     = tls_private_key.key.private_key_pem
  sensitive = true
}

output "public_ec2_ip" {
  value = aws_instance.public_ec2_01.public_ip
}