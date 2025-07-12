#!/bin/bash

# Usage: curl -sSL https://raw.githubusercontent.com/C2gl/easy-jelly/main/scripts/create_lxc.sh | bash -s -- \
#   --host <PROXMOX_HOST> --user <USER> --pass <PASSWORD> --node <NODE> --id <LXC_ID> --template <TEMPLATE_ID> --hostname <HOSTNAME> --pkg "vim git htop"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)     PROXMOX_HOST="$2"; shift 2 ;;
    --user)     USER="$2"; shift 2 ;;
    --pass)     PASSWORD="$2"; shift 2 ;;
    --node)     NODE="$2"; shift 2 ;;
    --id)       LXC_ID="$2"; shift 2 ;;
    --template) TEMPLATE_ID="$2"; shift 2 ;;
    --hostname) HOSTNAME="$2"; shift 2 ;;
    --pkg)      PKG_LIST="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Check required params
if [ -z "$PROXMOX_HOST" ] || [ -z "$USER" ] || [ -z "$PASSWORD" ] || [ -z "$NODE" ] || [ -z "$LXC_ID" ] || [ -z "$TEMPLATE_ID" ] || [ -z "$HOSTNAME" ]; then
  echo "Missing required parameters."
  echo "Usage: bash create_lxc.sh --host <PROXMOX_HOST> --user <USER> --pass <PASSWORD> --node <NODE> --id <LXC_ID> --template <TEMPLATE_ID> --hostname <HOSTNAME> --pkg \"vim git\""
  exit 1
fi

set -e

# Authenticate
AUTH_JSON=$(curl -sk -d "username=$USER&password=$PASSWORD" https://$PROXMOX_HOST:8006/api2/json/access/ticket)
TICKET=$(echo "$AUTH_JSON" | jq -r '.data.ticket')
CSRF=$(echo "$AUTH_JSON" | jq -r '.data.CSRFPreventionToken')

# Create LXC
curl -sk -X POST https://$PROXMOX_HOST:8006/api2/json/nodes/$NODE/lxc \
  -b "PVEAuthCookie=$TICKET" \
  -H "CSRFPreventionToken: $CSRF" \
  -d "vmid=$LXC_ID" \
  -d "ostemplate=$TEMPLATE_ID" \
  -d "hostname=$HOSTNAME" \
  -d "password=containerpassword" \
  -d "storage=local-lvm" \
  -d "cores=2" \
  -d "memory=2048" \
  -d "net0=name=eth0,bridge=vmbr0,ip=dhcp"

# Start LXC
curl -sk -X POST https://$PROXMOX_HOST:8006/api2/json/nodes/$NODE/lxc/$LXC_ID/status/start \
  -b "PVEAuthCookie=$TICKET" -H "CSRFPreventionToken: $CSRF"

# Install packages inside container (via pct exec)
if [ -n "$PKG_LIST" ]; then
  curl -sk -X POST "https://$PROXMOX_HOST:8006/api2/json/nodes/$NODE/lxc/$LXC_ID/exec" \
    -b "PVEAuthCookie=$TICKET" -H "CSRFPreventionToken: $CSRF" \
    -d "command=apt-get" -d "extra-args=update"
  curl -sk -X POST "https://$PROXMOX_HOST:8006/api2/json/nodes/$NODE/lxc/$LXC_ID/exec" \
    -b "PVEAuthCookie=$TICKET" -H "CSRFPreventionToken: $CSRF" \
    -d "command=apt-get" -d "extra-args=install -y $PKG_LIST"
fi

echo "LXC $LXC_ID created and packages installed."