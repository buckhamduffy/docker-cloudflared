#!/bin/sh

# Required environment variables validation
if [ -z "$CLOUDFLARE_TUNNEL_ID" ]; then
  echo "❌ Container failed to start: please pass CLOUDFLARE_TUNNEL_ID"
  exit 1
fi

if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
  echo "❌ Container failed to start: please pass CLOUDFLARE_ACCOUNT_ID"
  exit 1
fi

if [ -z "$CLOUDFLARE_TUNNEL_NAME" ]; then
  echo "❌ Container failed to start: please pass CLOUDFLARE_TUNNEL_NAME"
  exit 1
fi

if [ -z "$CLOUDFLARE_TUNNEL_SECRET" ]; then
  echo "❌ Container failed to start: please pass CLOUDFLARE_TUNNEL_SECRET"
  exit 1
fi

# Validate config input: either CLOUDFLARE_JSON, CLOUDFLARE_CONFIG_BASE64, or CLOUDFLARE_HOSTNAME + CLOUDFLARE_SERVICE
if [ -z "$CLOUDFLARE_HOSTNAME" ] && [ -z "$CLOUDFLARE_SERVICE" ] && [ -z "$CLOUDFLARE_JSON" ] && [ -z "$CLOUDFLARE_CONFIG_BASE64" ]; then
  echo "❌ Container failed to start: please pass either:"
  echo "   - CLOUDFLARE_HOSTNAME and CLOUDFLARE_SERVICE, or"
  echo "   - CLOUDFLARE_JSON, or"
  echo "   - CLOUDFLARE_CONFIG_BASE64"
  exit 1
fi

mkdir -p /etc/cloudflared

# Generate config.yaml if CLOUDFLARE_HOSTNAME + CLOUDFLARE_SERVICE provided
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

# Decode CLOUDFLARE_CONFIG_BASE64 into CLOUDFLARE_JSON if provided
if [ -n "$CLOUDFLARE_CONFIG_BASE64" ]; then 
  if ! CLOUDFLARE_JSON=$(echo "$CLOUDFLARE_CONFIG_BASE64" | base64 -d 2>/dev/null); then
    echo "❌ Failed to decode CLOUDFLARE_CONFIG_BASE64 (invalid base64 format)"
    exit 1
  fi
fi

# Generate config.yaml if CLOUDFLARE_JSON (decoded or direct) is provided
if [ -n "$CLOUDFLARE_JSON" ]; then 
  JSON="{\"ingress\": $CLOUDFLARE_JSON}"
  if ! SERVICES=$(echo "$JSON" | yq eval -P); then
    echo "❌ Failed to parse CLOUDFLARE_JSON using yq (invalid JSON format)"
    exit 1
  fi

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

# Write the tunnel credentials
cat > /etc/cloudflared/cert.json <<EOF
{
  "AccountTag": "${CLOUDFLARE_ACCOUNT_ID}",
  "TunnelID": "${CLOUDFLARE_TUNNEL_ID}",
  "TunnelName": "${CLOUDFLARE_TUNNEL_NAME}",
  "TunnelSecret": "${CLOUDFLARE_TUNNEL_SECRET}"
}
EOF

# Run cloudflared
cloudflared tunnel --config /etc/cloudflared/config.yaml run
