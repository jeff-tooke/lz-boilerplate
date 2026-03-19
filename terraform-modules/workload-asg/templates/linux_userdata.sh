#!/bin/bash
set -euo pipefail

################################################################################
# IMDSv2 — fetch token once, reuse for all metadata calls
################################################################################
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
HOSTNAME=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/hostname)
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)
INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-type)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

################################################################################
# Data volume — format and mount /dev/sdb if it exists and is unformatted
################################################################################
if [ -b /dev/sdb ]; then
  if ! blkid /dev/sdb &>/dev/null; then
    mkfs.ext4 /dev/sdb
  fi
  mkdir -p /data
  mount /dev/sdb /data
  # Persist across reboots
  DISK_UUID=$(blkid -s UUID -o value /dev/sdb)
  if ! grep -q "$DISK_UUID" /etc/fstab; then
    echo "UUID=$DISK_UUID /data ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
fi

################################################################################
# Install nginx (Amazon Linux 2023 uses dnf)
################################################################################
dnf update -y
dnf install -y nginx

################################################################################
# Write homepage
################################################################################
cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>workload-asg demo</title>
  <style>
    body { font-family: monospace; background: #1a1a2e; color: #e0e0e0; padding: 2rem; }
    h1   { color: #00d4ff; }
    table { border-collapse: collapse; margin-top: 1rem; }
    td, th { border: 1px solid #444; padding: 0.5rem 1rem; text-align: left; }
    th { background: #16213e; color: #00d4ff; }
    tr:nth-child(even) { background: #0f3460; }
  </style>
</head>
<body>
  <h1>workload-asg — Amazon Linux 2023</h1>
  <table>
    <tr><th>Field</th><th>Value</th></tr>
    <tr><td>Instance ID</td><td>$INSTANCE_ID</td></tr>
    <tr><td>Hostname</td><td>$HOSTNAME</td></tr>
    <tr><td>Private IP</td><td>$PRIVATE_IP</td></tr>
    <tr><td>Instance Type</td><td>$INSTANCE_TYPE</td></tr>
    <tr><td>Availability Zone</td><td>$AZ</td></tr>
  </table>
</body>
</html>
HTML

################################################################################
# Enable and start nginx
################################################################################
systemctl enable nginx
systemctl start nginx
