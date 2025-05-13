FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    tor \
    obfs4proxy \
    && rm -rf /var/lib/apt/lists/*

# تنظیم مالکیت با UID/GID واقعی
RUN mkdir -p /var/lib/tor /var/log/tor && \
    chown -R 100:101 /var/lib/tor /var/log/tor && \
    chmod -R 700 /var/lib/tor && \
    chmod -R 750 /var/log/tor

COPY torrc /etc/tor/torrc

EXPOSE 2096 8443

# استفاده از UID/GID به جای نام کاربری
USER 100:101

CMD ["tor", "-f", "/etc/tor/torrc"]
