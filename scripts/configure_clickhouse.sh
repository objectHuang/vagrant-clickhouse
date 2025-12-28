#!/bin/bash
set -e

# Arguments passed from Vagrant
NODE_NAME=$1
NODE_IP=$2
SHARD=$3
REPLICA=$4
IS_KEEPER=$5
KEEPER_ID=$6

echo "=== Configuring ClickHouse on ${NODE_NAME} ==="

# Create config.d directory if it doesn't exist
mkdir -p /etc/clickhouse-server/config.d

# Write cluster configuration
cat > /etc/clickhouse-server/config.d/cluster.xml << 'EOF'
<clickhouse>
    <remote_servers>
        <cluster>
            <shard>
                <internal_replication>true</internal_replication>
                <replica>
                    <host>192.168.8.11</host>
                    <port>9000</port>
                </replica>
                <replica>
                    <host>192.168.8.12</host>
                    <port>9000</port>
                </replica>
            </shard>
            <shard>
                <internal_replication>true</internal_replication>
                <replica>
                    <host>192.168.8.13</host>
                    <port>9000</port>
                </replica>
                <replica>
                    <host>192.168.8.14</host>
                    <port>9000</port>
                </replica>
            </shard>
        </cluster>
    </remote_servers>

    <zookeeper>
        <node>
            <host>192.168.8.11</host>
            <port>9181</port>
        </node>
        <node>
            <host>192.168.8.12</host>
            <port>9181</port>
        </node>
        <node>
            <host>192.168.8.13</host>
            <port>9181</port>
        </node>
    </zookeeper>

    <distributed_ddl>
        <path>/clickhouse/task_queue/ddl</path>
    </distributed_ddl>
</clickhouse>
EOF

# Write macros configuration (node-specific)
cat > /etc/clickhouse-server/config.d/macros.xml << EOF
<clickhouse>
    <macros>
        <cluster>cluster</cluster>
        <shard>${SHARD}</shard>
        <replica>${NODE_NAME}</replica>
    </macros>
</clickhouse>
EOF

# Write network configuration (node-specific)
cat > /etc/clickhouse-server/config.d/network.xml << EOF
<clickhouse>
    <listen_host>0.0.0.0</listen_host>
    <interserver_http_host>${NODE_IP}</interserver_http_host>
</clickhouse>
EOF

# Write keeper configuration if this node is a keeper
if [ "${IS_KEEPER}" = "true" ]; then
    cat > /etc/clickhouse-server/config.d/keeper.xml << EOF
<clickhouse>
    <keeper_server>
        <tcp_port>9181</tcp_port>
        <server_id>${KEEPER_ID}</server_id>
        <log_storage_path>/var/lib/clickhouse/coordination/log</log_storage_path>
        <snapshot_storage_path>/var/lib/clickhouse/coordination/snapshots</snapshot_storage_path>

        <coordination_settings>
            <operation_timeout_ms>10000</operation_timeout_ms>
            <session_timeout_ms>30000</session_timeout_ms>
            <raft_logs_level>warning</raft_logs_level>
        </coordination_settings>

        <raft_configuration>
            <server>
                <id>1</id>
                <hostname>192.168.8.11</hostname>
                <port>9234</port>
            </server>
            <server>
                <id>2</id>
                <hostname>192.168.8.12</hostname>
                <port>9234</port>
            </server>
            <server>
                <id>3</id>
                <hostname>192.168.8.13</hostname>
                <port>9234</port>
            </server>
        </raft_configuration>
    </keeper_server>
</clickhouse>
EOF
fi

# Set proper ownership
chown -R clickhouse:clickhouse /etc/clickhouse-server/config.d/

# Enable and start ClickHouse server
systemctl enable clickhouse-server
systemctl restart clickhouse-server

# Wait for ClickHouse to start
echo "Waiting for ClickHouse to start..."
sleep 10

# Check if ClickHouse is running
if systemctl is-active --quiet clickhouse-server; then
    echo "=== ClickHouse is running on ${NODE_NAME} ==="
else
    echo "=== Warning: ClickHouse may not have started properly ==="
    systemctl status clickhouse-server
fi
