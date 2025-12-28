# -*- mode: ruby -*-
# vi: set ft=ruby :

# ClickHouse Cluster Configuration
CLUSTER_NAME = "cluster"
NODES = [
  { name: "ch-node1", ip: "192.168.8.11", shard: 1, replica: 1, is_keeper: true, keeper_id: 1 },
  { name: "ch-node2", ip: "192.168.8.12", shard: 1, replica: 2, is_keeper: true, keeper_id: 2 },
  { name: "ch-node3", ip: "192.168.8.13", shard: 2, replica: 1, is_keeper: true, keeper_id: 3 },
  { name: "ch-node4", ip: "192.168.8.14", shard: 2, replica: 2, is_keeper: false, keeper_id: 0 },
]

Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 LTS
  config.vm.box = "ubuntu/jammy64"
  
  # Disable automatic box update checking
  config.vm.box_check_update = false

  NODES.each do |node|
    config.vm.define node[:name] do |node_config|
      node_config.vm.hostname = node[:name]
      node_config.vm.network "private_network", ip: node[:ip]

      # VirtualBox specific configuration
      node_config.vm.provider "virtualbox" do |vb|
        vb.name = node[:name]
        vb.memory = 8192
        vb.cpus = 4
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      end

      # Configure /etc/hosts
      node_config.vm.provision "shell", path: "scripts/configure_hosts.sh"

      # Install ClickHouse
      node_config.vm.provision "shell", path: "scripts/install_clickhouse.sh"

      # Configure ClickHouse cluster
      node_config.vm.provision "shell",
        path: "scripts/configure_clickhouse.sh",
        args: [
          node[:name],
          node[:ip],
          node[:shard].to_s,
          node[:replica].to_s,
          node[:is_keeper].to_s,
          node[:keeper_id].to_s
        ]
    end
  end
end
