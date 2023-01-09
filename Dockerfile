FROM cloudflare/cloudflared:latest 
FROM bash:5

COPY --from=0 /usr/local/bin/cloudflared /usr/local/bin/cloudflared

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
