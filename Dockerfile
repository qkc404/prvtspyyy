FROM haproxy:alpine
USER root

# Install dependencies required for Xray
RUN apk add --no-cache ca-certificates wget unzip

# Download latest stable Xray Core binary
RUN wget -qO /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -j /tmp/xray.zip xray -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && rm -rf /tmp/xray.zip

# Inject Ultra-Aggressive Adblocking & Tracking Geo-databases
RUN wget -qO /usr/local/bin/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat && \
    wget -qO /usr/local/bin/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat

# CRITICAL FIX: Explicitly declare asset paths so Xray core reads the ad-block files flawlessly
ENV XRAY_LOCATION_ASSET=/usr/local/bin

# Copy configuration files
COPY config.json /etc/xray.json
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

EXPOSE 8080

# Starts xray immediately in background, then hands over foreground thread control to HAProxy
CMD /usr/local/bin/xray run -c /etc/xray.json & exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg