
---
title: es7.x 安装
date: 2020-09-21 12:48
categories:
- elasticsearch
tags:
- es
- elasticsearch
---




## 下载elasticsearch

```
https://www.elastic.co/cn/downloads/elasticsearch
```

```
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.8.0-linux-x86_64.tar.gz
```

## 系统优化

vim /etc/security/limits.conf
```
* soft nofile 65535
* hard nofile 65536
* soft nproc  16384
* hard nproc  16384
* soft stack  10240
* soft memlock unlimited
* hard memlock unlimited
```

```
swapoff -a
# 禁用swapping，开启服务器虚拟内存交换功能会对es产生致命的打击
```

vim /etc/sysctl.conf
```
vm.swappiness = 1
vm.zone_reclaim_mode = 0
vm.overcommit_memory=1
vm.swappiness=0
net.core.somaxconn=65535
net.ipv4.tcp_max_syn_backlog=65535
net.ipv4.tcp_syncookies = 1
vm.swappiness = 0

vm.dirty_ratio=10
vm.max_map_count=655360
```


## 创建用户和用户组
```
useradd -M -s /sbin/nologin es
```


```
tar xf elasticsearch-7.8.0-linux-x86_64.tar.gz
mv elasticsearch-7.8.0 /home/es/elasticsearch-7.8.0

chown es.es -R elasticsearch
ln -s /home/es/elasticsearch-7.8.0 /home/es/elasticsearch
mkdir /home/es/elasticsearch/data
```



## 配置es

```
cat >> config/elasticsearch.yml <<EOF

# ======================== Elasticsearch Configuration =========================
cluster.name: cluster-Es
node.name: node01
network.host: 172.16.103.123
node.master: true
node.data: true
# head 插件需要这打开这两个配置
http.cors.allow-origin: "*"
http.cors.enabled: true
http.max_content_length: 200mb
# 可以选举的主节点
cluster.initial_master_nodes: ["192.168.7.41:9300","192.168.7.42:9300","192.168.7.43:9300"]
discovery.seed_hosts: ["192.168.7.41:9300","192.168.7.42:9300","192.168.7.43:9300"]
gateway.recover_after_nodes: 2
network.tcp.keep_alive: true
network.tcp.no_delay: true
transport.tcp.compress: true
#集群内同时启动的数据任务个数，默认是2个
cluster.routing.allocation.cluster_concurrent_rebalance: 16
#添加或删除节点及负载均衡时并发恢复的线程个数，默认4个
cluster.routing.allocation.node_concurrent_recoveries: 16
#初始化数据恢复时，并发恢复线程的个数，默认4个
cluster.routing.allocation.node_initial_primaries_recoveries: 16
#开启 xpack 功能，如果要禁止使用密码，请将以下内容注释，直接启动不需要设置密码
#xpack.security.enabled: true
#xpack.security.transport.ssl.enabled: true
#xpack.security.transport.ssl.verification_mode: certificate
#xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
#xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
EOF
```



启动

```
su - es -c "/home/es/elasticsearch/bin/elasticsearch -d"
```



启动二

配置 services 文件

```
vim /lib/systemd/system/elasticsearch.service


[Unit]
Description=elasticsearch
After=network.target
[Service]
Type=simple
User=es
Group=es
WorkingDirectory=/opt/elasticsearch
LimitNOFILE=100000
LimitNPROC=100000
Restart=no
ExecStart=/opt/elasticsearch/bin/elasticsearch
PrivateTmp=true
[Install]
WantedBy=multi-user.target
```





```
systemctl daemon-reload
systemctl start elasticsearch
systemctl status elasticsearch
systemctl stop elasticsearch
```



