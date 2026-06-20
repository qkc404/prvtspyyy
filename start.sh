#!/bin/sh

echo "Starting Xray Core..."
/usr/local/bin/xray run -c /etc/xray.json &

echo "Starting HAProxy..."
exec haproxy -db -f /usr/local/etc/haproxy/haproxy.cfg
