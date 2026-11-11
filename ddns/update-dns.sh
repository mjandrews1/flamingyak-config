#!/bin/bash
# Flaming Yak - Porkbun Dynamic DNS Updater
# Updates A records for flamingyak.com, flamingyak.net, flamingyak.org
# and their www subdomains
#
# Usage: ./update-dns.sh
# Cron: Run every 5 minutes via cron

# Porkbun API credentials - REPLACE THESE WITH YOUR OWN
API_KEY="YOUR_PORKBUN_API_KEY"
API_SECRET="YOUR_PORKBUN_API_SECRET"

# All domains to update
DOMAINS=("flamingyak.com" "flamingyak.net" "flamingyak.org")

# Get current public IP
PUBLIC_IP=$(curl -s https://api.ipify.org)

# Log file
LOG_FILE="/var/log/ddns.log"

for DOMAIN in "${DOMAINS[@]}"; do
  # Get all records for this domain
  RESPONSE=$(curl -s -X GET "https://api.porkbun.com/api/json/v3/dns/retrieve/$DOMAIN" \
    -H "X-API-KEY: $API_KEY" \
    -H "X-Secret-API-Key: $API_SECRET")
  
  # Update @ record (name = "@" in Porkbun API)
  RECORD_ID=$(echo "$RESPONSE" | jq -r ".records[] | select(.type == \"A\" and (.name == \"@\" or .name == \"$DOMAIN\")) | .id")
  CURRENT_IP=$(echo "$RESPONSE" | jq -r ".records[] | select(.type == \"A\" and (.name == \"@\" or .name == \"$DOMAIN\")) | .content")
  
  if [ "$RECORD_ID" = "" ] || [ "$RECORD_ID" = "null" ]; then
    # Record doesn't exist, create it with name="@"
    curl -s -X POST "https://api.porkbun.com/api/json/v3/dns/create/$DOMAIN" \
      -H "X-API-KEY: $API_KEY" \
      -H "X-Secret-API-Key: $API_SECRET" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"A\",\"name\":\"@\",\"content\":\"$PUBLIC_IP\",\"ttl\":600}"
    echo "$(date) - Created $DOMAIN @: $PUBLIC_IP" >> "$LOG_FILE"
  elif [ "$CURRENT_IP" != "$PUBLIC_IP" ]; then
    # Record exists, update it
    curl -s -X POST "https://api.porkbun.com/api/json/v3/dns/edit/$DOMAIN/$RECORD_ID" \
      -H "X-API-KEY: $API_KEY" \
      -H "X-Secret-API-Key: $API_SECRET" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"A\",\"name\":\"@\",\"content\":\"$PUBLIC_IP\",\"ttl\":600}"
    echo "$(date) - Updated $DOMAIN @: $PUBLIC_IP" >> "$LOG_FILE"
  else
    echo "$(date) - $DOMAIN @ unchanged: $PUBLIC_IP" >> "$LOG_FILE"
  fi
  
  # Update www record
  WWW_RECORD_ID=$(echo "$RESPONSE" | jq -r ".records[] | select(.type == \"A\" and .name == \"www\") | .id")
  CURRENT_WWW_IP=$(echo "$RESPONSE" | jq -r ".records[] | select(.type == \"A\" and .name == \"www\") | .content")
  
  if [ "$WWW_RECORD_ID" = "" ] || [ "$WWW_RECORD_ID" = "null" ]; then
    # www record doesn't exist, create it with name="www"
    curl -s -X POST "https://api.porkbun.com/api/json/v3/dns/create/$DOMAIN" \
      -H "X-API-KEY: $API_KEY" \
      -H "X-Secret-API-Key: $API_SECRET" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"A\",\"name\":\"www\",\"content\":\"$PUBLIC_IP\",\"ttl\":600}"
    echo "$(date) - Created $DOMAIN www: $PUBLIC_IP" >> "$LOG_FILE"
  elif [ "$CURRENT_WWW_IP" != "$PUBLIC_IP" ]; then
    # www record exists, update it
    curl -s -X POST "https://api.porkbun.com/api/json/v3/dns/edit/$DOMAIN/$WWW_RECORD_ID" \
      -H "X-API-KEY: $API_KEY" \
      -H "X-Secret-API-Key: $API_SECRET" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"A\",\"name\":\"www\",\"content\":\"$PUBLIC_IP\",\"ttl\":600}"
    echo "$(date) - Updated $DOMAIN www: $PUBLIC_IP" >> "$LOG_FILE"
  else
    echo "$(date) - $DOMAIN www unchanged: $PUBLIC_IP" >> "$LOG_FILE"
  fi
done
