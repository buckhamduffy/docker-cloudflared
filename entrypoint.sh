#!/bin/bash

if [ -z "$CLOUDFLARE_TUNNEL_ID" ]; then
  echo "Container failed to start, please pass CLOUDFLARE_TUNNEL_ID"
  exit 1
fi

if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
  echo "Container failed to start, please pass CLOUDFLARE_ACCOUNT_ID"
  exit 1
fi

if [ -z "$CLOUDFLARE_TUNNEL_NAME" ]; then
  echo "Container failed to start, please pass CLOUDFLARE_TUNNEL_NAME"
  exit 1
fi

if [ -z "$CLOUDFLARE_TUNNEL_SECRET" ]; then
  echo "Container failed to start, please pass CLOUDFLARE_TUNNEL_SECRET"
  exit 1
fi

if [ -z "$CLOUDFLARE_HOSTNAME" ]; then
  echo "Container failed to start, please pass CLOUDFLARE_HOSTNAME"
  exit 1
fi

if [ -z "$CLOUDFLARE_SERVICE" ]; then
  echo "Container failed to start, please pass CLOUDFLARE_TUNNEL_SECRET"
  exit 1
fi

mkdir -p /etc/cloudflared

cat > /etc/cloudflared/config.yaml <<EOF
tunnel: ${CLOUDFLARE_TUNNEL_ID}
credentials-file: /etc/cloudflared/cert.json
logfile: /etc/cloudflared/cloudflared.log
loglevel: info
no-autoupdate: true
ingress:
  - hostname: ${CLOUDFLARE_HOSTNAME}
    service: ${CLOUDFLARE_SERVICE}
  - service: http_status:404
EOF

cat > /etc/cloudflared/cert.json <<EOF
{
  "AccountTag": "${CLOUDFLARE_ACCOUNT_ID}",
  "TunnelID": "${CLOUDFLARE_TUNNEL_ID}",
  "TunnelName": "${CLOUDFLARE_TUNNEL_NAME}",
  "TunnelSecret": "${CLOUDFLARE_TUNNEL_SECRET}"
}
EOF

cloudflared tunnel --config /etc/cloudflared/config.yaml $@