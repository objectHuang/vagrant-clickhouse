# Vagrant ClickHouse Cluster

A Vagrant-based project to automatically provision a fully functional ClickHouse cluster with ClickHouse Keeper for distributed coordination.

## Overview

This project creates a 4-node ClickHouse cluster with:
- **2 shards** with **2 replicas** each (for high availability)
- **3 ClickHouse Keeper nodes** (built-in ZooKeeper alternative for coordination)
- Automatic cluster configuration and replication setup

## Cluster Architecture

| Node | IP Address | Shard | Replica | Keeper |
|------|-----------|-------|---------|--------|
| ch-node1 | 192.168.8.11 | 1 | 1 | ✅ (ID: 1) |
| ch-node2 | 192.168.8.12 | 1 | 2 | ✅ (ID: 2) |
| ch-node3 | 192.168.8.13 | 2 | 1 | ✅ (ID: 3) |
| ch-node4 | 192.168.8.14 | 2 | 2 | ❌ |

### Network Ports

| Port | Service |
|------|---------|
| 9000 | ClickHouse native protocol |
| 8123 | ClickHouse HTTP interface |
| 9181 | ClickHouse Keeper |
| 9234 | Keeper Raft protocol |

## Prerequisites

- [Vagrant](https://www.vagrantup.com/downloads) (2.0+)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (6.0+)
- At least **32GB RAM** (each VM uses 8GB)
- At least **16 CPU cores** (each VM uses 4 cores)

## Quick Start

### 1. Start the Cluster

```bash
# Clone the repository and navigate to the directory
cd vagrant-clickhouse

# Start all VMs (this may take 10-15 minutes)
vagrant up
```

### 2. Verify the Cluster

```bash
# SSH into any node
vagrant ssh ch-node1

# Connect to ClickHouse
clickhouse-client

# Check cluster status
SELECT * FROM system.clusters WHERE cluster = 'cluster';

# Check Keeper status
SELECT * FROM system.zookeeper WHERE path = '/';
```

### 3. Create a Replicated Table

```sql
-- Create a database on the cluster
CREATE DATABASE IF NOT EXISTS test ON CLUSTER 'cluster';

-- Create a replicated table
CREATE TABLE test.events ON CLUSTER 'cluster'
(
    id UInt64,
    event_time DateTime,
    event_type String,
    data String
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/events', '{replica}')
ORDER BY (event_time, id);

-- Create a distributed table for querying across shards
CREATE TABLE test.events_distributed ON CLUSTER 'cluster'
AS test.events
ENGINE = Distributed('cluster', 'test', 'events', rand());
```

## VM Management

```bash
# Start all VMs
vagrant up

# Stop all VMs (preserves data)
vagrant halt

# Restart all VMs
vagrant reload

# Destroy all VMs (removes all data)
vagrant destroy -f

# SSH into a specific node
vagrant ssh ch-node1
vagrant ssh ch-node2
vagrant ssh ch-node3
vagrant ssh ch-node4

# Check status of all VMs
vagrant status
```

## Configuration Files

The provisioning scripts create the following configuration files on each node:

| File | Description |
|------|-------------|
| `/etc/clickhouse-server/config.d/cluster.xml` | Cluster topology and Keeper connection |
| `/etc/clickhouse-server/config.d/macros.xml` | Node-specific macros (shard, replica) |
| `/etc/clickhouse-server/config.d/network.xml` | Network listening configuration |
| `/etc/clickhouse-server/config.d/keeper.xml` | Keeper configuration (nodes 1-3 only) |

## Project Structure

```
vagrant-clickhouse/
├── README.md                           # This file
├── Vagrantfile                         # Vagrant configuration
└── scripts/
    ├── configure_hosts.sh              # Configure /etc/hosts
    ├── install_clickhouse.sh           # Install ClickHouse packages
    └── configure_clickhouse.sh         # Configure cluster settings
```

## Troubleshooting

### Check ClickHouse Service Status

```bash
vagrant ssh ch-node1
sudo systemctl status clickhouse-server
sudo journalctl -u clickhouse-server -f
```

### Check Keeper Status

```bash
# From clickhouse-client
SELECT * FROM system.zookeeper WHERE path = '/clickhouse';

# Check Keeper logs
sudo tail -f /var/log/clickhouse-server/clickhouse-server.log | grep -i keeper
```

### Common Issues

1. **VMs fail to start**: Ensure VirtualBox is installed and you have enough RAM/CPU
2. **Cluster not forming**: Wait 1-2 minutes for Keeper quorum to establish
3. **Replication not working**: Verify all nodes can reach each other on the private network

## Customization

To modify the cluster configuration, edit the `NODES` array in the `Vagrantfile`:

```ruby
NODES = [
  { name: "ch-node1", ip: "192.168.8.11", shard: 1, replica: 1, is_keeper: true, keeper_id: 1 },
  # Add or modify nodes here
]
```

## License

MIT License
