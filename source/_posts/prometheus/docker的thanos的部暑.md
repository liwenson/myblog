---
title: docker的thanos的部暑
date: 2021-09-08 17:41
categories:
- prometheus
tags:
- prome
- thanos
---
	
	
摘要: desc
<!-- more -->

## 架构

10.200.92.117 
	thanos / querier
	thanos / storer
	thanos / compactor
	minio 

10.200.76.70
	prometheus
	thanos / sidecar

## thanos 组件


## 目录创建
```
mkdir -p /opt/prome 
cd /opt/prome
mkdir -p minio/data
mkdir thanos
```

## 配置文件

创建thanos 调用minio 的配置文件

```
vim thanos/bucket_config.yaml

type: S3
config:
  bucket: "thanos"
  endpoint: '10.200.92.117:9001'  # minio 接口地址
  access_key: "root"
  secret_key: "TTP7Jwho"   #设置s3密码，保证8位以上的长度
  insecure: true     #是否使用安全协议http或https
  signature_version2: false
  encrypt_sse: false
  put_user_metadata: {}
  http_config:
    idle_conn_timeout: 90s
    response_header_timeout: 2m
    insecure_skip_verify: false
  trace:
    enable: false
  part_size: 134217728

```

prometheus 配置文件,。必须定义extends label，用于区分相同metrics的数据源
```
global:
  scrape_interval:     60s
  evaluation_interval: 60s
  external_labels:
    monitor: 'base'

#常规配置...
```


## 应用启动
### thanos 

```
vim docker-compose.yml



version: '2'
services:

##############################################################
  # to search on old metrics
  storer:
    container_name: storer
    image: quay.io/thanos/thanos:v0.13.0-rc.2
    volumes:
    - /opt/prome/thanos/bucket_config.yaml:/bucket_config.yaml
    command:
    - store
    - --data-dir=/var/thanos/store
    - --objstore.config-file=bucket_config.yaml
    - --http-address=0.0.0.0:19191
    - --grpc-address=0.0.0.0:19090
    depends_on:
      - minio  
    networks:
      - prom

  # downsample metrics on the bucket
  compactor:
    container_name: compactor
    image: quay.io/thanos/thanos:v0.13.0-rc.2
    volumes:
    - /opt/prome/thanos/bucket_config.yaml:/bucket_config.yaml
    command:
    - compact
    - --data-dir=/var/thanos/compact
    - --objstore.config-file=bucket_config.yaml
    - --http-address=0.0.0.0:19191
    - --wait
    depends_on:
      - minio 
    networks:
      - prom

  # querier component which can be scaled
  querier:
    container_name: querier
    image: quay.io/thanos/thanos:v0.13.0-rc.2
#    labels:
#      - "traefik.enable=true"
#      - "traefik.port=19192"
#      - "traefik.frontend.rule=PathPrefix:/"
    ports: 
      - "19192:19192"
    command:
      - query
      - --http-address=0.0.0.0:19192
      - --store=10.200.76.70:19292
      - --store=storer:19090
      - --query.replica-label=replica
    networks:
      - prom

  minio:
    image: minio/minio:latest
    container_name: minio
    ports:
      - 9000:9000
      - 9001:9001
    volumes: 
      - "/opt/prome/minio/data:/data"
    environment:
      MINIO_ROOT_USER: "root"
      MINIO_ROOT_PASSWORD: "TTP7Jwho" #输入8位以上的密码
    command: "server /data --console-address :9000 --address :9001"
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "5m"
        max-file: "3"
    networks:
      - prom


# 按需启用
#  node-exporter:
#    image: prom/node-exporter:latest
#    container_name: node-exporter
#    ports:
#      - '9100:9100'


networks:
  prom:
    driver: bridge


```



## prometheus 

web.enable-lifecycle 一定要开，用于热加载时 reload 你的配置，retention 保留 2 小时，Prometheus 默认 2 小时会生成一个 block，Thanos 会把这个 block 上传到对象存储。

prometheus抓取到的监控数据在落盘之前都是存储在内存中的，所以适当的减小数据落盘时间可以减小内存的压力
storage.tsdb.max-block-duration: 设置数据块最小时间跨度，默认 2h 的数据量。监控数据是按块（block）存储，每一个块中包含该时间窗口内的所有样本数据（data chunks)
storage.tsdb.min-block-duration	设置数据块最大时间跨度，默认为最大保留时间的 10%


```
mkdir -p /opt/prom/{prometheus,thanos}
```


```
vim docker-compose.yml

version: '3.7'

services:

# 按需启用
#  node-exporter:
#    image: prom/node-exporter:latest
#    ports:
#      - "9100:9100"
#    networks:
#      - prom

#  dingtalk:
#    image: timonwong/prometheus-webhook-dingtalk:latest
#    volumes:
#      - type: bind
#        source: ./alertmanager/config.yml
#        target: /etc/prometheus-webhook-dingtalk/config.yml
#        read_only: true
#    ports:
#      - "8060:8060"
#    networks:
#      - prom

  alertmanager:
#    depends_on:
#      - dingtalk
    image: prom/alertmanager:latest
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - type: bind
        source: ./alertmanager/alertmanager.yml
        target: /etc/alertmanager/alertmanager.yml
        read_only: true
    command: 
      - --config.file=/etc/alertmanager/alertmanager.yml 
      - --web.external-url=http://10.200.76.70:9093

    ports:
      - "9093:9093"
      - "9094:9094"
    networks:
      - prom

  prometheus:
    depends_on:
      - alertmanager
    image: prom/prometheus:latest
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - type: bind
        source: ./prometheus/prometheus.yml
        target: /etc/prometheus/prometheus.yml
        read_only: true
 #     - type: bind
 #       source: ./prometheus/rules/alert-rules.yml
 #       target: /etc/prometheus/alert-rules.yml
 #       read_only: true
      - type: volume
        source: prometheus
        target: /prometheus
      - "/opt/prom/prometheus/rules:/etc/prometheus/rules"
      - "/opt/prom/prometheus/targets:/etc/prometheus/targets"
    command: 
      - --config.file=/etc/prometheus/prometheus.yml 
      - --storage.tsdb.path=/prometheus 
      - --storage.tsdb.retention=60d 
      - --web.enable-lifecycle
      - --web.enable-admin-api 
      - --web.external-url=http://10.200.76.70:9090
#      - --storage.tsdb.min-block-duration = --storage.tsdb.max-block-duration
      - --storage.tsdb.min-block-duration=6d
      - --storage.tsdb.max-block-duration=6d
    ports:
      - "9090:9090"
    networks:
      - prom


  grafana:
    depends_on:
      - prometheus
    image: grafana/grafana:latest
    volumes:
      - type: volume
        source: grafana
        target: /var/lib/grafana
    ports:
      - "3000:3000"
    networks:
      - prom


  black-exporter:
    environment:
      - TZ=Asia/Shanghai
    image: prom/blackbox-exporter:latest
    volumes:
      - /opt/prom/black-exporter/blackbox.yml:/config/blackbox.yml
    command:
      - '--config.file=/config/blackbox.yml'
    ports:
      - '9115:9115'
    networks:
      - prom

  sidecar:
    container_name: sidecar
    image: quay.io/thanos/thanos:v0.13.0-rc.2
    logging:
      driver: "json-file"
      options:
        max-size: "5m"
        max-file: "3"
    volumes:
      - type: volume
        source: prometheus
        target: /var/prometheus
      - /opt/prom/thanos/bucket_config.yaml:/bucket_config.yaml
    command:
      - sidecar
      - --tsdb.path=/var/prometheus
      - --prometheus.url=http://10.200.76.70:9090
      - --objstore.config-file=/bucket_config.yaml
      - --http-address=0.0.0.0:19191
      - --grpc-address=0.0.0.0:19292
    ports:
      - "19191:19191"
      - "19292:19292"
    depends_on:
      - prometheus
    networks:
      - prom

volumes:
  prometheus:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/prom/prometheus/data
  grafana:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/prom/grafana
      
networks:
  prom:
    driver: bridge


```