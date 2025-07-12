# easy-jelly
easy automated jellyfin setup 



# Easy Proxmox LXC Creator

## Quickstart

Run this from anywhere (requires `jq` installed):

```bash
curl -sSL https://raw.githubusercontent.com/C2gl/easy-jelly/main/scripts/create_lxc.sh | bash -s -- \
  --host proxmox.example.com \
  --user root@pam \
  --pass yourpassword \
  --node pve \
  --id 110 \
  --template local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst \
  --hostname awesome-container \
  --pkg "vim git htop"
```

## Arguments

- `--host`      Proxmox host (IP or FQDN)
- `--user`      Proxmox username (e.g., root@pam)
- `--pass`      Proxmox password
- `--node`      Proxmox node name
- `--id`        Container VMID
- `--template`  Template ID (as in Proxmox)
- `--hostname`  Container hostname
- `--pkg`       Space-separated package list

## Security

**Do not share your Proxmox credentials.**  
Consider using environment variables or secrets for sensitive information.
