# WireGuard Setup Guide

## Overview

WireGuard is installed as a VPN server on your VPS. All traffic from connected
devices is tunneled through the VPS (full tunnel). This guide covers connecting
devices, adding new peers, and troubleshooting.

## Quick Start

### 1. Download the Client Config

The installer creates a config for your first device at:

```
/opt/lemon-vps/host/wireguard/clients/laptop.conf
```

Download it to your local machine:

```bash
scp root@YOUR_VPS_IP:/opt/lemon-vps/host/wireguard/clients/laptop.conf .
```

### 2. Import into WireGuard

- **Windows / macOS / Linux:** Download the WireGuard app, click **Import tunnel(s) from file**
- **Android / iOS:** Download the WireGuard app, tap **+** → **Import from file or archive**

### 3. Connect

Toggle the tunnel on. All your traffic now routes through the VPS.

## Adding a New Device

### On the VPS

```bash
sudo bash /opt/lemon-vps/host/wireguard/add-peer.sh <device-name>
```

Examples:

```bash
sudo bash /opt/lemon-vps/host/wireguard/add-peer.sh phone
sudo bash /opt/lemon-vps/host/wireguard/add-peer.sh work-laptop
sudo bash /opt/lemon-vps/host/wireguard/add-peer.sh tablet
```

This will:

1. Generate a new keypair and preshared key
2. Assign the next available IP (10.0.0.3, 10.0.0.4, etc.)
3. Add the peer to the server config
4. Write a client config file
5. Apply the change live (no restart needed)

### Download the New Config

```bash
scp root@YOUR_VPS_IP:/opt/lemon-vps/host/wireguard/clients/<device-name>.conf .
```

### Import into WireGuard App

Follow the same steps as the Quick Start above.

## Checking Connected Devices

```bash
# On the VPS — show all peers and their latest handshake
sudo wg show wg0
```

Output:

```
interface: wg0
  public key: <server-public-key>
  private key: (hidden)
  listening port: 51820

peer: <client-public-key>
  endpoint: <client-ip>:<port>
  allowed ips: 10.0.0.2/32
  latest handshake: 30 seconds ago
  transfer: 1.24 MiB received, 5.67 MiB sent
```

If you see **latest handshake**, the device is connected.

## Removing a Device

1. Remove the peer section from the server config:

```bash
sudo nano /etc/wireguard/wg0.conf
# Delete the [Peer] block with the comment # peer:<device-name>
```

2. Apply the change:

```bash
sudo wg syncconf wg0 <(wg-quick strip wg0)
```

3. Delete the client config (optional):

```bash
sudo rm /opt/lemon-vps/host/wireguard/clients/<device-name>.conf
```

## DNS

Connected devices use DNS based on what's installed:

- **NextDNS installed:** DNS is `10.0.0.1` (NextDNS on the VPS)
- **No NextDNS:** DNS is `9.9.9.9` (Quad9)

The DNS is set automatically in the client config. To verify:

```bash
grep DNS /opt/lemon-vps/host/wireguard/clients/<device-name>.conf
```

## Full Tunnel vs Split Tunnel

By default, all traffic is routed through the VPN (`AllowedIPs = 0.0.0.0/0`).

### To Split Tunnel (Only Route Some Traffic)

Edit the client config and change `AllowedIPs`:

```ini
[Peer]
# Only route VPS local network + specific subnets
AllowedIPs = 10.0.0.0/24, 192.168.1.0/24
```

Common split tunnel configs:

| Use case | AllowedIPs |
|----------|------------|
| Full tunnel (default) | `0.0.0.0/0, ::/0` |
| Only VPS LAN | `10.0.0.0/24` |
| VPS LAN + home network | `10.0.0.0/24, 192.168.1.0/24` |
| Specific services only | `10.0.0.1/32` (DNS only) |

## Troubleshooting

### Can't connect to VPS

```bash
# Check WireGuard is running
sudo systemctl status wg-quick@wg0

# Check port is open
sudo ss -ulnp | grep 51820

# Check UFW allows WireGuard
sudo ufw status | grep 51820
```

### Connected but no internet

```bash
# Check IP forwarding is enabled
cat /proc/sys/net/ipv4/ip_forward
# Should return: 1

# Check NAT rule
sudo iptables -t nat -L POSTROUTING -n | grep MASQUERADE

# Check DOCKER-USER chain
sudo iptables -L DOCKER-USER -n | grep wg0
```

### Connected but can't reach VPS services

```bash
# Check UFW allows LAN traffic
sudo ufw status | grep wg0

# Test from another device on VPN
ping 10.0.0.1
curl https://cloud.{{DOMAIN}}
```

### Handshake but no traffic

```bash
# Check for IP conflicts
ip addr show wg0

# Check MTU (usually fine at default 1420)
sudo wg show wg0
```

### Restarting WireGuard

```bash
sudo systemctl restart wg-quick@wg0
```

## Server Management

```bash
# Show interface info
sudo wg show

# Show listening port
sudo ss -ulnp | grep 51820

# Show all assigned IPs
sudo wg show wg0 allowed-ips

# Regenerate server keys (CAUTION: invalidates all client configs)
sudo wg genkey | tee /etc/wireguard/server.key | wg pubkey > /etc/wireguard/server.pub
```

## Further Reading

- [WireGuard Quick Start](https://www.wireguard.com/quickstart/)
- [WireGuard Man Page](https://www.wireguard.com/compilation/)
- [WireGuard on Linux](https://www.wireguard.com/install/)
