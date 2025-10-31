variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "eu-central-1"
}

variable "project" {
  description = "Base name used for tagging AWS resources."
  type        = string
  default     = "vpn-server"
}

variable "instance_type" {
  description = "EC2 instance type for the WireGuard server."
  type        = string
  default     = "t3.micro"
}

variable "ssh_key_name" {
  description = "Existing AWS EC2 key pair name used for SSH access."
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to reach the server over SSH."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "wireguard_allowed_cidrs" {
  description = "List of CIDR blocks allowed to reach the WireGuard UDP port."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "wireguard_network_cidr" {
  description = "Internal WireGuard network used between the server and clients."
  type        = string
  default     = "10.44.0.0/24"
}

variable "wireguard_port" {
  description = "UDP port exposed for WireGuard."
  type        = number
  default     = 51820
}

variable "wireguard_dns_servers" {
  description = "DNS servers advertised to clients over the VPN."
  type        = list(string)
  default     = ["1.1.1.1", "1.0.0.1"]
}

variable "client_allowed_ips" {
  description = "List of CIDR blocks routed through the WireGuard tunnel on the client."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}
