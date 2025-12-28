#!/bin/bash
set -e

echo "=== Installing ClickHouse ==="

# Install prerequisites
apt-get update
apt-get install -y apt-transport-https ca-certificates dirmngr gnupg2

# Add ClickHouse repository
GNUPGHOME=$(mktemp -d)
GNUPGHOME="$GNUPGHOME" gpg --no-default-keyring --keyring /usr/share/keyrings/clickhouse-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8919F6BD2B48D754
rm -rf "$GNUPGHOME"
chmod +r /usr/share/keyrings/clickhouse-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main" | tee /etc/apt/sources.list.d/clickhouse.list

apt-get update

# Install ClickHouse (non-interactive)
DEBIAN_FRONTEND=noninteractive apt-get install -y clickhouse-server clickhouse-client

echo "=== ClickHouse installed successfully ==="
