FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    tor \
    obfs4proxy && \
    rm -rf /var/lib/apt/lists/*

COPY torrc /etc/tor/torrc

RUN mkdir -p /var/lib/tor /var/log/tor

USER 100:101

EXPOSE 2096 8443

CMD ["tor", "-f", "/etc/tor/torrc"]
