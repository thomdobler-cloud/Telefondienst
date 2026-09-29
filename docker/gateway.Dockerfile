FROM caddy:2-alpine
COPY docker/Caddyfile.railway /etc/caddy/Caddyfile
ENV PORT=8080
EXPOSE 8080
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
