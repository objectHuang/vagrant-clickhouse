#!/bin/bash
set -e

echo "=== Configuring /etc/hosts ==="

# Add all cluster nodes to /etc/hosts
cat >> /etc/hosts << EOF
192.168.8.11 ch-node1
192.168.8.12 ch-node2
192.168.8.13 ch-node3
192.168.8.14 ch-node4
EOF

echo "=== /etc/hosts configured ==="
