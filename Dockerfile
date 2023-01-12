FROM cloudflare/cloudflared:latest 
FROM bash:5

COPY --from=0 /usr/local/bin/cloudflared /usr/local/bin/cloudflared

RUN wget https://github.com/mikefarah/yq/releases/download/v4.30.6/yq_linux_amd64 -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
