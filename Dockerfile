FROM haproxy:alpine
USER root

RUN apk add --no-cache ca-certificates wget unzip

# Download latest stable Xray Core binary
RUN wget -qO /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -j /tmp/xray.zip xray -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && rm -rf /tmp/xray.zip

COPY config.json /etc/xray.json
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY index.html /usr/local/etc/haproxy/index.html
COPY start.sh /start.sh

# Make the startup script executable
RUN chmod +x /start.sh

EXPOSE 8080

# Run the reliable startup script
CMD ["/start.sh"]
