#!/bin/bash
set -euxo pipefail

FLAG_FILE="/opt/wireguard/bootstrap.complete"

if [[ -f "$FLAG_FILE" ]]; then
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y wireguard wireguard-tools iptables curl

install -d -m 700 /etc/wireguard/keys

SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(printf "%s" "$SERVER_PRIVATE_KEY" | wg pubkey)
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(printf "%s" "$CLIENT_PRIVATE_KEY" | wg pubkey)
PRESHARED_KEY=$(wg genpsk)

printf "%s" "$SERVER_PRIVATE_KEY" >/etc/wireguard/keys/server_private.key
printf "%s" "$SERVER_PUBLIC_KEY" >/etc/wireguard/keys/server_public.key
printf "%s" "$CLIENT_PRIVATE_KEY" >/etc/wireguard/keys/client_private.key
printf "%s" "$CLIENT_PUBLIC_KEY" >/etc/wireguard/keys/client_public.key
printf "%s" "$PRESHARED_KEY" >/etc/wireguard/keys/preshared.key
chmod 600 /etc/wireguard/keys/*.key

PRIMARY_INTERFACE=$(ip -4 route list default | awk '{print $5; exit}')

cat >/etc/sysctl.d/60-wireguard-ip-forwarding.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

sysctl --system

cat >/etc/wireguard/wg0.conf <<EOF
[Interface]
Address = ${server_address_cidr}
ListenPort = ${wireguard_port}
MTU = 1310
SaveConfig = true
PrivateKey = $SERVER_PRIVATE_KEY
PostUp = iptables -t nat -A POSTROUTING -o $PRIMARY_INTERFACE -j MASQUERADE; iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o $PRIMARY_INTERFACE -j MASQUERADE; iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
PresharedKey = $PRESHARED_KEY
AllowedIPs = ${client_address_cidr}
EOF

SERVER_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

cat >${client_config_path} <<EOF
[Interface]
Address = ${client_address_cidr}
PrivateKey = $CLIENT_PRIVATE_KEY
DNS = ${dns_servers_line}

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $PRESHARED_KEY
Endpoint = $SERVER_PUBLIC_IP:${wireguard_port}
AllowedIPs = ${client_allowed_ips}
PersistentKeepalive = 25
EOF

chmod 600 ${client_config_path}
chown ${ubuntu_username}:${ubuntu_username} ${client_config_path}

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

touch "$FLAG_FILE"
