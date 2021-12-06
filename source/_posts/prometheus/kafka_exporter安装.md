---
title: kafka_exporter安装
date: 2021-10-28 17:42
categories:
- prometheus
tags:
- kafka_exporter
---
	
	
摘要: kafka_exporter安装
<!-- more -->

大数据组件中，Kafka使用非常广泛。而提及Kafka的监控，历来都是个头疼的事情，Kafka的开源社区在监控框架上并没有投入太多的精力。（Cloudera倒是有一个关于Kafka独立的产品Cloudera Streams Management）

下面是几种常见的Kafka监控方案：

- JMXTool
- Kafka Manager
- Kafka Eagle
- Kafka Center（最近才开源，没有做测试）


Prometheus + Grafana
以上开源监控方案，各有千秋，Kafka Manager，Kafka Eagle，适合基本的Kafka监控。如果企业已经使用上Prometheus，也非常方便将Kafka的监控集成到Prometheus上。即采用kafka_exporter采集Kafka的metrics，发送到Prometheus，使用Grafana进行展示。


kafka_exporter安装

下载地址：https://github.com/danielqsj/kafka_exporter/releases


创建日志目录，编写启动脚本
```
mkdir -p /opt/kafka_exporter/{bin,logs}
cd /opt/kafka_exporter/
tar xf kafka_exporter-1.4.2.linux-amd64.tgz
ln -s /opt/kafka_exporter/kafka_exporter-1.4.2.linux-amd64/kafka_exporter bin/kafka_exporter



# 编写kafka_exporter启动服务
vim /usr/lib/systemd/system/kafka_exporter.service
 
[Unit]
Description=kafka_exporter
Documentation=https://github.com/danielqsj/kafka_exporter/
Wants=network-online.target
After=network-online.target
 
[Service]
ExecStart=/opt/kafka_exporter/bin/kafka_exporter --kafka.server=10.200.76.53:9092 
 
[Install]
WantedBy=multi-user.target



# 配置开机启动
systemctl daemon-reload
systemctl enable kafka_exporter
systemctl start kafka_exporter
systemctl status kafka_exporter
```

```
http://10.200.92.107:9308/metrics
```
