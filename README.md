# VPN Server on AWS with WireGuard

Terraform configuration for a personal WireGuard VPN server in AWS (Frankfurt), plus setup notes for macOS and a GL.iNet GL-MT1300 “Shadow” travel router.

## Features
- One-click deployment of an Ubuntu EC2 instance with WireGuard pre-configured.
- Automatic key generation and client profile (`client-wg0.conf`) stored on the server.
- Security groups exposing only SSH and WireGuard.
- Documentation for macOS and GL.iNet router clients to route all traffic through the tunnel.

## Getting Started
1. Copy `terraform/terraform.tfvars.example` (create it if needed) and set:
   - `ssh_key_name` to your EC2 key pair.
   - Optional overrides for allowed CIDRs, DNS servers, etc.
2. Deploy:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```
3. Retrieve the client profile from `/home/ubuntu/client-wg0.conf` via `scp`.
4. Follow `docs/client-setup.md` to configure macOS and the GL.iNet router.

## Maintenance
- Regenerate keys by deleting `/opt/wireguard/bootstrap.complete` on the instance and rebooting.
- Destroy resources with `terraform destroy` when you’re finished.

## License
MIT — see `LICENSE`. Use at your own risk. Keys and client configs should remain out of version control.
