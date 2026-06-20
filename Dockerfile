FROM haproxy:alpine
USER root

# Install dependencies required for Xray
RUN apk add --no-cache ca-certificates wget unzip

# Download latest stable Xray Core binary
RUN wget -qO /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -j /tmp/xray.zip xray -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && rm -rf /tmp/xray.zip

# Copy configuration files and UI
COPY config.json /etc/xray.json
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY index.html /usr/local/etc/haproxy/index.html

EXPOSE 8080

# Run Xray in the background, but force HAProxy to the foreground (-db) to keep the container alive
CMD /usr/local/bin/xray run -c /etc/xray.json & exec haproxy -db -f /usr/local/etc/haproxy/haproxy.cfg
