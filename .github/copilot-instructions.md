# VPN Server - AI Coding Agent Instructions

## Project Overview
This is a personal WireGuard VPN server deployment on AWS EC2 using Terraform. Single-user setup focused on simplicity, security, and cost-effectiveness with dynamic IP addressing in the Frankfurt (eu-central-1) region.

## Architecture & Key Components

### Infrastructure (Terraform)
- **EC2 Instance**: Single t3.micro/t3.small instance in Frankfurt (eu-central-1)
- **Security Groups**: Allow WireGuard port (51820/UDP) and SSH (22/TCP) from your IP
- **VPC Setup**: Default VPC with public subnet for simplicity
- **Dynamic IP**: No Elastic IP needed - use EC2 public IP with dynamic DNS or manual updates (preferred at this point)

### WireGuard Configuration
- **Server Config**: `/etc/wireguard/wg0.conf` with single peer (you)
- **Key Management**: Server private/public keys + client private/public keys
- **Network**: Simple point-to-point tunnel (e.g., 10.0.0.1/24 server, 10.0.0.2/32 client)
- **Traffic Routing**: All client traffic routed through VPN with IP forwarding

### Security Patterns
- **Key-Based Auth**: WireGuard's built-in public key cryptography (no passwords)
- **Minimal Attack Surface**: Only SSH and WireGuard ports exposed
- **EC2 Security**: Use AWS IAM roles, disable password auth, SSH key-only access
- **Firewall**: UFW or iptables rules for additional protection

## Development Workflows

### Infrastructure Deployment
```bash
# Initialize and validate Terraform
terraform init
terraform validate
terraform plan

# Deploy infrastructure to Frankfurt
terraform apply

# Get server IP and connection details
terraform output server_ip
terraform output ssh_command
```

### WireGuard Setup
```bash
# SSH into the server
ssh -i ~/.ssh/your-key.pem ubuntu@$(terraform output -raw server_ip)

# Generate WireGuard keys (automated via user-data script)
sudo wg genkey | sudo tee /etc/wireguard/server_private.key
sudo cat /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key

# Start WireGuard service
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Generate client config
sudo ./scripts/generate-client-config.sh
```

### Local Client Setup
```bash
# Download client config from server
scp -i ~/.ssh/your-key.pem ubuntu@SERVER_IP:/home/ubuntu/client.conf ~/client.conf

# Connect using WireGuard client
wg-quick up ~/client.conf
wg-quick down ~/client.conf
```

## Project Conventions

### Terraform Structure
```
terraform/
├── main.tf           # Primary AWS resources (EC2, security groups)
├── variables.tf      # Input variables (region, instance type, key pair)
├── outputs.tf        # Server IP, SSH commands, connection info
├── user-data.sh      # EC2 initialization script for WireGuard setup
└── terraform.tfvars # Your personal config (excluded from git)
```

### WireGuard Configuration
- Server config template in `templates/wg0.conf.tpl`
- Client config generation script in `scripts/generate-client-config.sh`
- Key files stored securely on server only (`/etc/wireguard/`)
- Use `wg show` for connection status and `journalctl -u wg-quick@wg0` for logs

### AWS Conventions
- **Region**: Always eu-central-1 (Frankfurt) for consistency
- **Tags**: Include Environment=personal, Project=vpn-server
- **Instance Type**: t3.micro for cost optimization (upgrade to t3.small if needed)
- **AMI**: Latest Ubuntu 22.04 LTS for WireGuard compatibility

### Security Best Practices
- Never commit private keys or terraform.tfvars to git
- Use `.gitignore` for sensitive files (*.key, terraform.tfvars, *.conf)
- Use strong pre-shared keys for additional WireGuard security

## Integration Points
- **AWS Provider**: Configure Terraform with AWS credentials and Frankfurt region
- **EC2 Instance**: Ubuntu 22.04 LTS with user-data script for automated WireGuard setup
- **Dynamic DNS**: Optional integration with services like DuckDNS for stable hostname
- **Local WireGuard Client**: macOS/iOS WireGuard app or `brew install wireguard-tools`

## Key Files to Reference
- `README.md`: Setup instructions and deployment guide
- `SECURITY.md`: Security policies and vulnerability reporting
- `docs/protocol.md`: VPN protocol specification and wire format
- `scripts/deploy.sh`: Production deployment automation
- `config/example.conf`: Well-documented configuration template
