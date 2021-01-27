
---
title: es7.x 安装
date: 2020-09-21 12:48
categories:
- elasticsearch
tags:
- es
- elasticsearch
---




下载elasticsearch

```
https://www.elastic.co/cn/downloads/elasticsearch
```

```
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.8.0-linux-x86_64.tar.gz
```

```
tar xf elasticsearch-7.8.0-linux-x86_64.tar.gz
mv elasticsearch-7.8.0 /home/es/elasticsearch-7.8.0
chown es.es -R elasticsearch
ln -s /home/es/elasticsearch-7.8.0 /home/es/elasticsearch
```



配置es

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
Description=Elasticsearch
Documentation=http://www.elastic.co
Wants=network-online.target
After=network-online.target

[Service]
RuntimeDirectory=elasticsearch
PrivateTmp=true
Environment=ES_HOME=/home/es/elasticsearch
Environment=ES_PATH_CONF=/etc/elasticsearch
Environment=PID_DIR=/var/run/elasticsearch
EnvironmentFile=-/etc/sysconfig/elasticsearch

WorkingDirectory=/home/es/elasticsearch

User=es
Group=es

ExecStart=/home/es/elasticsearch/bin/elasticsearch -p ${PID_DIR}/elasticsearch.pid --quiet

# StandardOutput is configured to redirect to journalctl since
# some error messages may be logged in standard output before
# elasticsearch logging system is initialized. Elasticsearch
# stores its logs in /var/log/elasticsearch and does not use
# journalctl by default. If you also want to enable journalctl
# logging, you can simply remove the "quiet" option from ExecStart.
StandardOutput=journal
StandardError=inherit

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Specifies the maximum number of processes
LimitNPROC=4096

# Specifies the maximum size of virtual memory
LimitAS=infinity

# Specifies the maximum file size
LimitFSIZE=infinity

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=0

# SIGTERM signal is used to stop the Java process
KillSignal=SIGTERM

# Send the signal only to the JVM rather than its control group
KillMode=process

# Java process is never killed
SendSIGKILL=no

# When a JVM receives a SIGTERM signal it exits with code 143
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target

# Built for packages-7.1.1 (packages)
```





```
systemctl daemon-reload
systemctl start elasticsearch
systemctl status elasticsearch
systemctl stop elasticsearch
```



运行elasticsearch时报错：

```
could not find java; set JAVA_HOME or ensure java is in PATH
```

修改文件

```
vim bin/elasticsearch-env

添加
source /etc/profile

修改  ES_HOME=`dirname "$SCRIPT"`   为    ES_HOME="/home/es/elasticsearch"
```

