# 🚀 Flaming Yak - Quick Start Reference

## Daily Commands

```bash
# Update DNS (all domains)
lxc exec ddns -- /opt/update-dns.sh

# Check DNS status
lxc exec ddns -- tail -20 /var/log/ddns.log

# Restart Caddy
lxc exec frontend -- systemctl restart caddy

# Check Caddy logs
lxc exec frontend -- journalctl -u caddy -n 20

# Check container status
lxc list

# Check UFW status
sudo ufw status verbose

# Check fail2ban status
sudo fail2ban-client status
```

## Domain Status

| Domain | DNS | HTTPS | Status |
|--------|-----|-------|--------|
| flamingyak.com | ✅ | ✅ | Working |
| www.flamingyak.com | ✅ | ✅ | Working |
| flamingyak.net | ✅ | ⚠️ | DNS OK, SSL pending |
| www.flamingyak.net | ✅ | ✅ | Working |
| flamingyak.org | ✅ | ✅ | Working |
| www.flamingyak.org | ✅ | ✅ | Working |

## Service Status

```bash
# Check all services
sudo systemctl status ufw fail2ban
lxc list
```

## Common Issues

### DNS not updating
```bash
# Manual update
lxc exec ddns -- /opt/update-dns.sh

# Check Porkbun API
curl -s 'https://api.porkbun.com/api/json/v3/ping' \
  -H 'X-API-KEY: pk1_...' \
  -H 'X-Secret-API-Key: sk1_...'
```

### SSL not working
```bash
# Check DNS propagation
dig flamingyak.com

# Check Caddy logs
lxc exec frontend -- journalctl -u caddy -f

# Wait and retry (Let's Encrypt rate limits)
```

### Can't access web server
```bash
# Check UFW
sudo ufw status

# Check Caddy
lxc exec frontend -- systemctl status caddy

# Check proxy devices
lxc config device list frontend

# Test locally
curl http://127.0.0.1:80
```

## Repository Info

```bash
# Location
~/projects/flamingyak-config

# Update from repo
cd ~/projects/flamingyak-config
git pull

# Check changes
git status

# Update DDNS script
lxc file push ddns/update-dns.sh ddns/opt/update-dns.sh
lxc exec ddns -- chmod +x /opt/update-dns.sh
```
