FROM caddy:builder AS builder

RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
    xcaddy build \
    --with github.com/caddyserver/forwardproxy

FROM caddy:latest

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
