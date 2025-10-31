# VPN Client Setup

These instructions cover deploying the WireGuard server with Terraform, collecting the generated client profile, and configuring both a macOS workstation and a GL.iNet GL-MT1300 "Shadow" travel router to tunnel all traffic through the VPN.

## Prerequisites
- Terraform 1.5+ installed locally.
- AWS credentials configured with permissions to manage EC2, VPC, and security groups in `eu-central-1`.
- An existing EC2 key pair in Frankfurt (name provided via `var.ssh_key_name`).
- Homebrew (for macOS WireGuard tools) and access to the GL.iNet router admin UI.

## 1. Deploy the WireGuard Server
1. Populate `terraform/terraform.tfvars` with project-specific values (example below):
   ```hcl
   aws_region            = "eu-central-1"
   ssh_key_name          = "my-frankfurt-keypair"
   ssh_allowed_cidrs     = ["203.0.113.10/32"]
   wireguard_allowed_cidrs = ["0.0.0.0/0"]
   ```
2. Initialize and apply:
   ```bash
   cd terraform
   terraform init
   terraform validate
   terraform plan
   terraform apply
   ```
3. Note the `server_public_ip`, `wireguard_port`, and `client_config_remote_path` outputs; you will need them shortly.

## 2. Retrieve the Client Configuration
1. SSH to the instance using the key pair referenced in Terraform (replace the placeholder with your key path):
   ```bash
   ssh -i ~/.ssh/my-frankfurt-keypair.pem ubuntu@$(terraform output -raw server_public_ip)
   ```
2. Confirm that WireGuard is running:
   ```bash
   sudo systemctl status wg-quick@wg0
   sudo wg show
   ```
3. Copy the generated client configuration to your local machine:
   ```bash
   scp -i ~/.ssh/my-frankfurt-keypair.pem \
     ubuntu@$(terraform output -raw server_public_ip):/home/ubuntu/client-wg0.conf \
     ./client-wg0.conf
   ```
4. Store the file securely; it contains private keys.

## 3. macOS Client Configuration
1. Install the official WireGuard app from the Mac App Store (recommended UI client). If you prefer the command-line tools, run:
   ```bash
   brew install wireguard-tools
   ```
2. Launch the app, choose **Import tunnel(s) from file**, and select `client-wg0.conf`.
3. Review the profile. Ensure `AllowedIPs = 0.0.0.0/0, ::/0` so that all traffic is routed through the VPN.
4. Activate the tunnel. macOS should report a successful connection within a few seconds.
5. Verify:
   ```bash
   curl https://ifconfig.me
   ```
   The reported IP should match `server_public_ip`.
6. (Optional) Enable “On-Demand” within the WireGuard app if you want the tunnel to reconnect automatically on network changes.

## 4. GL.iNet GL-MT1300 “Shadow” Router Configuration
1. Connect a laptop to the router (wired or Wi-Fi) and browse to `http://192.168.8.1`.
2. Log in, then navigate to **VPN > WireGuard Client**.
3. Click **Set up WireGuard Client** → **Import Config File**, choose `client-wg0.conf`, and provide a friendly profile name.
4. After the profile appears, click **Connect**. The status should switch to “Connected” and show handshake statistics.
5. Under **VPN Dashboard**, choose **Use VPN for All Clients** to ensure every device behind the router routes traffic through the tunnel.
6. (Optional but recommended) Enable the **Kill Switch** to block outbound traffic if the VPN disconnects unexpectedly.
7. Confirm the router is using the tunnel by visiting `https://ifconfig.me` from a device connected through the router; the IP should match `server_public_ip`.

## 5. Ongoing Operations
- **Dynamic IP updates**: If the EC2 public IP changes, update the `Endpoint` line in `client-wg0.conf` or rerun the `scp` step after refreshing the server public IP.
- **Rotating keys**: Regenerate credentials by deleting `/opt/wireguard/bootstrap.complete` on the server and rebooting; the user-data script will produce fresh keys and configs.
- **Tearing down**: When finished, run `terraform destroy` inside the `terraform/` directory to remove all AWS resources.

Keep the client configuration files and SSH keys secure. Never commit them to version control or share them over insecure channels.
