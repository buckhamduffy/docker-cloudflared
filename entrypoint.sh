#!/bin/sh

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

if [ -z "$CLOUDFLARE_HOSTNAME" ] && [ -z "$CLOUDFLARE_JSON" ]; then
  echo "Container failed to start, please pass CLOUDFLARE_HOSTNAME or CLOUDFLARE_JSON"
  exit 1
fi

if [ -z "$CLOUDFLARE_SERVICE" ] && [ -z "$CLOUDFLARE_JSON" ]; then
  echo "Container failed to start, please pass CLOUDFLARE_TUNNEL_SECRET or CLOUDFLARE_JSON"
  exit 1
fi

mkdir -p /etc/cloudflared

if [ -n "$CLOUDFLARE_SERVICE" ] && [ -n "$CLOUDFLARE_HOSTNAME" ]; then
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
fi

if [ -n "$CLOUDFLARE_JSON" ]; then 
  JSON="{\"ingress\": $CLOUDFLARE_JSON}"
  SERVICES=$(echo "$JSON" | yq eval -P )


  cat > /etc/cloudflared/config.yaml <<EOF
tunnel: ${CLOUDFLARE_TUNNEL_ID}
credentials-file: /etc/cloudflared/cert.json
logfile: /etc/cloudflared/cloudflared.log
loglevel: info
no-autoupdate: true
$SERVICES
  - service: http_status:404
EOF
fi

cat > /etc/cloudflared/cert.json <<EOF
{
  "AccountTag": "${CLOUDFLARE_ACCOUNT_ID}",
  "TunnelID": "${CLOUDFLARE_TUNNEL_ID}",
  "TunnelName": "${CLOUDFLARE_TUNNEL_NAME}",
  "TunnelSecret": "${CLOUDFLARE_TUNNEL_SECRET}"
}
EOF

cloudflared tunnel --config /etc/cloudflared/config.yaml run