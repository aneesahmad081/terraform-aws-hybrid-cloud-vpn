#!/bin/bash
set -euxo pipefail

# No public IP, no NAT gateway and no package downloads required.
mkdir -p /opt/hybrid-vpn-demo
cat > /opt/hybrid-vpn-demo/index.html <<'HTML'
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>Hybrid VPN Lab</title></head>
<body style="font-family:system-ui; margin:48px">
<h1>Hybrid Cloud VPN Lab - Connected!</h1>
<p>This private web page is served from EC2 in eu-north-1.</p>
<p>If you can access it via 10.100.0.10:8080 from the router in us-east-1,
private connectivity through AWS Site-to-Site VPN is working.</p>
</body></html>
HTML

cat > /etc/systemd/system/hybrid-vpn-demo.service <<'UNIT'
[Unit]
Description=Private hybrid VPN demonstration HTTP server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=nobody
WorkingDirectory=/opt/hybrid-vpn-demo
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 0.0.0.0 --directory /opt/hybrid-vpn-demo
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now hybrid-vpn-demo.service
