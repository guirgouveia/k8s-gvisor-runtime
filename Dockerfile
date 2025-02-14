FROM ubuntu:20.04

WORKDIR /host

RUN apt-get update && apt-get install -y \
    systemctl \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY install-gvisor.sh /usr/local/bin/install-gvisor.sh
RUN chmod +x /usr/local/bin/install-gvisor.sh

ENTRYPOINT ["/usr/local/bin/install-gvisor.sh"]