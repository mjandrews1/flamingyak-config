# Flaming Yak - LXD Front-End Configuration

This repository contains the configuration for the LXD-based front-end server running on u01 (Mac Mini).

## Architecture Overview

```
Internet
    ↓ (Dynamic Public IP)
AT&T Quantum Fiber Router
    ↓ (Ports 80/443 forwarded to 192.168.0.16)
u01 (Mac Mini - 192.168.0.16 in DMZ)
    ├── UFW Firewall
    ├── fail2ban
    └── LXD
        ├── frontend (Caddy + HTTPS)
        └── ddns (Porkbun DNS Updater)
```

## Domains

- flamingyak.com
- flamingyak.net
- flamingyak.org

All domains point to the public IP and resolve to the Caddy web server on the frontend container.

## Directory Structure

```
flamingyak-config/
├── README.md                 # This file
├── ddns/
│   └── update-dns.sh         # Dynamic DNS update script
├── caddy/
│   └── Caddyfile             # Caddy web server configuration
├── lxd/
│   └── containers.conf       # LXD container specifications
└── docs/
    └── setup-guide.md        # Setup instructions
```

## Quick Start

### 1. Initialize LXD
```bash
lxd init
```

### 2. Create Containers
```bash
lxc launch ubuntu:24.04 frontend --config limits.cpu=1 --config limits.memory=512MiB
lxc launch ubuntu:24.04 ddns --config limits.cpu=1 --config limits.memory=256MiB
```

### 3. Set Up Proxy Devices
```bash
lxc config device add frontend http proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80
lxc config device add frontend https proxy listen=tcp:0.0.0.0:443 connect=tcp:127.0.0.1:443
```

### 4. Configure DDNS
See `ddns/update-dns.sh` - Update with your Porkbun API credentials.

### 5. Configure Caddy
See `caddy/Caddyfile` - Update with your domain names.

### 6. Install Security
```bash
sudo apt install -y ufw fail2ban
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## Configuration Files

### DDNS Script (`ddns/update-dns.sh`)
- Updates Porkbun DNS records every 5 minutes via cron
- Handles all three domains and their www subdomains
- Automatically creates missing A records

### Caddy Configuration (`caddy/Caddyfile`)
- Serves static placeholder page
- Auto-HTTPS with Let's Encrypt
- Handles all three domains and www subdomains

## Security Features

1. **UFW Firewall**: Default deny incoming, only allows SSH/HTTP/HTTPS
2. **fail2ban**: Protects SSH from brute force attacks
3. **LXD Isolation**: Containers are isolated from the host
4. **Dynamic DNS**: Automatically updates DNS when IP changes

## Management Commands

### Update DNS
```bash
lxc exec ddns -- /opt/update-dns.sh
```

### Restart Caddy
```bash
lxc exec frontend -- systemctl restart caddy
```

### Check Container Status
```bash
lxc list
lxc info frontend
lxc info ddns
```

### Check Logs
```bash
# DDNS logs
lxc exec ddns -- cat /var/log/ddns.log

# Caddy logs
lxc exec frontend -- journalctl -u caddy -f

# UFW logs
sudo cat /var/log/ufw.log

# fail2ban logs
sudo tail -f /var/log/fail2ban.log
```

## Troubleshooting

### DNS Not Updating
1. Check Porkbun API credentials in `ddns/update-dns.sh`
2. Run script manually: `lxc exec ddns -- /opt/update-dns.sh`
3. Check Porkbun API status

### SSL Not Working
1. Verify DNS records: `dig flamingyak.com`
2. Check Caddy logs: `lxc exec frontend -- journalctl -u caddy -n 50`
3. Wait 1-2 hours for Let's Encrypt rate limits

### Connection Blocked
1. Check UFW: `sudo ufw status verbose`
2. Check fail2ban: `sudo fail2ban-client status`
3. Verify router port forwarding

## Resources

- [Porkbun API Documentation](https://porkbun.com/api/json/v3)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [LXD Documentation](https://linuxcontainers.org/lxd/)
- [UFW Documentation](https://help.ubuntu.com/community/UFW)
- [fail2ban Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page)
