#!/bin/bash
set -euxo pipefail

cat > /etc/sysctl.d/99-hybrid-vpn.conf <<'SYSCTL'
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
SYSCTL
sysctl --system

# The SSM association will also install this if user-data is still running.
dnf install -y libreswan
systemctl enable ipsec

# Preinstalled on standard AL2023 EC2 AMIs; don't fail boot if already active.
systemctl enable --now amazon-ssm-agent || true
