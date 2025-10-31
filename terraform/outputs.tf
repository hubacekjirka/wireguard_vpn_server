output "server_public_ip" {
  description = "Public IPv4 address of the WireGuard server."
  value       = aws_instance.wireguard.public_ip
}

output "server_public_dns" {
  description = "Public DNS name of the WireGuard server."
  value       = aws_instance.wireguard.public_dns
}

output "wireguard_port" {
  description = "UDP port exposed for WireGuard."
  value       = var.wireguard_port
}

output "ssh_connection" {
  description = "Convenience command for SSH access (update with your private key path)."
  value       = format("ssh -i <path-to-private-key> ubuntu@%s", aws_instance.wireguard.public_ip)
}

output "client_config_remote_path" {
  description = "Location of the generated client configuration on the EC2 instance."
  value       = "/home/ubuntu/client-wg0.conf"
}
