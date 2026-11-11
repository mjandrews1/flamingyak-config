# Flaming Yak Setup Guide

## Prerequisites

- Ubuntu Server 24.04 (or similar)
- LXD installed and initialized
- Porkbun account with API access
- Domain names registered at Porkbun
- AT&T Quantum Fiber with DMZ or port forwarding configured

## Step 1: Initialize LXD

```bash
lxd init
```

Accept defaults or customize as needed. This creates:
- Default storage pool (dir type)
- Network bridge (lxdbr0)

## Step 2: Create Containers

### Frontend Container (Caddy Web Server)
```bash
lxc launch ubuntu:24.04 frontend --config limits.cpu=1 --config limits.memory=512MiB
```

### DDNS Container (Porkbun DNS Updater)
```bash
lxc launch ubuntu:24.04 ddns --config limits.cpu=1 --config limits.memory=256MiB
```

## Step 3: Configure Frontend Container

### Install Caddy
```bash
lxc exec frontend -- bash -c "
apt update && apt install -y curl debian-keyring debian-archive-keyring
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main' > /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install -y caddy
"
```

### Configure Caddy
```bash
lxc exec frontend -- bash -c "
cat > /etc/caddy/Caddyfile << 'CADLYEOF'
flamingyak.com, www.flamingyak.com, flamingyak.net, www.flamingyak.net, flamingyak.org, www.flamingyak.org {
    root * /var/www/html
    file_server
}
CADLYEOF

mkdir -p /var/www/html
echo '<html><body><h1>Welcome to Flaming Yak!</h1></body></html>' > /var/www/html/index.html

systemctl restart caddy
"
```

### Set Up Proxy Devices
```bash
lxc config device add frontend http proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80
lxc config device add frontend https proxy listen=tcp:0.0.0.0:443 connect=tcp:127.0.0.1:443
```

## Step 4: Configure DDNS Container

### Install Dependencies
```bash
lxc exec ddns -- bash -c "
apt update && apt install -y curl jq cron
"
```

### Deploy Update Script
```bash
# Copy from this repo
lxc file push ddns/update-dns.sh ddns/opt/update-dns.sh
lxc exec ddns -- chmod +x /opt/update-dns.sh
```

### Edit Script with Your API Credentials
```bash
lxc exec ddns -- nano /opt/update-dns.sh
```

Replace:
- `YOUR_PORKBUN_API_KEY` with your actual Porkbun API key
- `YOUR_PORKBUN_API_SECRET` with your actual Porkbun API secret

### Set Up Cron Job
```bash
lxc exec ddns -- bash -c "
echo '*/5 * * * * root /opt/update-dns.sh >> /var/log/ddns.log 2>&1' > /etc/cron.d/porkbun-ddns
chmod 644 /etc/cron.d/porkbun-ddns
service cron start
"
```

## Step 5: Configure Host Security

### Install UFW and fail2ban
```bash
sudo apt update
sudo apt install -y ufw fail2ban
```

### Configure UFW
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Configure fail2ban
```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## Step 6: Configure Porkbun DNS

1. Log in to Porkbun
2. Go to DNS → Edit for each domain
3. Add A records:
   - Type: A, Name: @, Value: <your-public-ip>, TTL: 600
   - Type: A, Name: www, Value: <your-public-ip>, TTL: 600

Or run the DDNS script once to create them:
```bash
lxc exec ddns -- /opt/update-dns.sh
```

## Step 7: Test Everything

### Test Caddy
```bash
curl http://192.168.0.16:80
```

### Test HTTPS (after DNS propagates)
```bash
curl https://flamingyak.com
curl https://flamingyak.net
curl https://flamingyak.org
```

### Check Container Status
```bash
lxc list
lxc info frontend
lxc info ddns
```

### Check Logs
```bash
# DDNS
lxc exec ddns -- cat /var/log/ddns.log

# Caddy
lxc exec frontend -- journalctl -u caddy -n 50

# UFW
sudo tail -f /var/log/ufw.log

# fail2ban
sudo tail -f /var/log/fail2ban.log
```

## Step 8: Optional Hardening

### Restrict SSH to Your IP
```bash
sudo ufw deny ssh
sudo ufw allow from YOUR_HOME_IP to any port 22
```

### Add fail2ban Jail for Caddy
```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
# Edit and add Caddy jail
sudo systemctl restart fail2ban
```

## Troubleshooting

### DNS Not Updating
- Check Porkbun API credentials
- Run script manually: `lxc exec ddns -- /opt/update-dns.sh`
- Check API response: `curl -s 'https://api.porkbun.com/api/json/v3/ping' -H 'X-API-KEY: ...' -H 'X-Secret-API-Key: ...'`

### SSL Not Working
- Verify DNS: `dig flamingyak.com`
- Check Caddy logs: `lxc exec frontend -- journalctl -u caddy -n 50`
- Wait 1-2 hours for Let's Encrypt rate limits

### Connection Blocked
- Check UFW: `sudo ufw status verbose`
- Check fail2ban: `sudo fail2ban-client status`
- Verify router port forwarding

## Cloning This Repository

To set up on a new machine:
```bash
git clone <repository-url> flamingyak-config
cd flamingyak-config

# Follow the steps above
```
