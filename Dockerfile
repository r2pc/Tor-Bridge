FROM ubuntu:24.04

# نصب Tor و obfs4proxy
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      tor \
      obfs4proxy \
    && rm -rf /var/lib/apt/lists/*

# ایجاد دایرکتوری‌ها
RUN mkdir -p /var/lib/tor /var/log/tor && \
    chown -R debian-tor:debian-tor /var/lib/tor /var/log/tor

# کپی فایل پیکربندی
COPY config/torrc /etc/tor/torrc

USER debian-tor
ENTRYPOINT ["tor", "-f", "/etc/tor/torrc"]
