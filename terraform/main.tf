terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  network_prefix_length = tonumber(split("/", var.wireguard_network_cidr)[1])
  server_ipv4           = cidrhost(var.wireguard_network_cidr, 1)
  client_ipv4           = cidrhost(var.wireguard_network_cidr, 2)
  server_address_cidr   = format("%s/%d", local.server_ipv4, local.network_prefix_length)
  client_address_cidr   = format("%s/32", local.client_ipv4)
  dns_servers_line      = join(", ", var.wireguard_dns_servers)
  client_allowed_ips    = join(", ", var.client_allowed_ips)
  tags = {
    Project     = var.project
    Environment = "personal"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "wireguard" {
  name        = "${var.project}-wireguard-sg"
  description = "Controls access to the WireGuard VPN server."
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = var.ssh_allowed_cidrs
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.wireguard_allowed_cidrs
    content {
      description = "WireGuard UDP"
      from_port   = var.wireguard_port
      to_port     = var.wireguard_port
      protocol    = "udp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [
      "::/0",
    ]
  }

  tags = local.tags
}

resource "aws_instance" "wireguard" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.wireguard.id]
  key_name                    = var.ssh_key_name
  user_data = templatefile("${path.module}/user-data.sh", {
    server_address_cidr = local.server_address_cidr
    wireguard_port      = var.wireguard_port
    client_address_cidr = local.client_address_cidr
    client_allowed_ips  = local.client_allowed_ips
    dns_servers_line    = local.dns_servers_line
    ubuntu_username     = "ubuntu"
    client_config_path  = "/home/ubuntu/client-wg0.conf"
  })

  user_data_replace_on_change = true

  root_block_device {
    volume_size = 8
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring = false

  tags = merge(
    local.tags,
    {
      Name = "${var.project}-wireguard"
    }
  )
}
