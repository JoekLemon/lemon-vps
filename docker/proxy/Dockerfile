FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install --yes squid && \
    rm -rf /var/lib/apt/lists/*

COPY config/squid.conf /etc/squid/squid.conf

EXPOSE 3128

CMD ["squid", "-N", "-d", "1"]
