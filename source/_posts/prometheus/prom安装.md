---
title: prometheus使用docker-compose安装
date: 2021-05-17 16:59
categories:
- prometheus
tags:
- prometheus
---
  
  
摘要: prometheus使用docker-compose 
<!-- more -->


## 目录创建
```
mkdir -p /opt/prom/{prometheus,alertmanager,black-exporter,grafana}
```

## 创建docker-compose文件
cd /opt/prom/
vim docker-compose.yaml
```
version: '3.7'

services:
  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    networks:
      - prom

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
    command: "--config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --storage.tsdb.retention=180d --web.enable-admin-api"
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

## prometheus 配置文件
### 初始化目录
```
mkdir -p data rules targets
```

### 创建prometheus.yml配置文件
cd prometheus
vim prometheus.yml
```
global:
  scrape_interval:     15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - alertmanager:9093

rule_files:
  - "/etc/prometheus/rules/*.yml"
  #- "*rules.yml"
  
scrape_configs:
  - job_name: 'node-target'
    file_sd_configs:
    - files:
      - "/etc/prometheus/targets/node/xwms/target.yml"
      - "/etc/prometheus/targets/node/jingtian/target.yml"
      - "/etc/prometheus/targets/node/zop/target.yml"
      - "/etc/prometheus/targets/node/zms/target.yml"
      - "/etc/prometheus/targets/node/yunpei/target.yml"
      - "/etc/prometheus/targets/node/oa/target.yml"
      - "/etc/prometheus/targets/node/dba/target.yml"
      - "/etc/prometheus/targets/node/bms/target.yml"
      - "/etc/prometheus/targets/node/bigdata/target.yml"
      refresh_interval: 10s 

  - job_name: 'prometheus'
    static_configs:
    - targets: ['prometheus:9090']

  - job_name: 'node'
    static_configs:
    - targets: ['node-exporter:9100']

  - job_name: 'alertmanager'
    static_configs:
    - targets: ['alertmanager:9093']

  - job_name: 'jmx'
    file_sd_configs:
    - files:
      - "/etc/prometheus/targets/jmx/target.yml"
      refresh_interval: 3m


  - job_name: 'prjectVer'
    scrape_interval: 120s
    metrics_path: '/actuator1/project/version'
    file_sd_configs:
    - files:
      - "/etc/prometheus/targets/prjectVer/target.yml"
      refresh_interval: 1m

  - job_name: "Website-monitor"
    scrape_interval: 60s
    metrics_path: /probe
    params:
      module: [http_2xx]
    file_sd_configs:
    - files:
      - "/etc/prometheus/targets/website/target.yml"
      refresh_interval: 3m

    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 10.200.76.70:9115
```
### 添加ruls
```
https://awesome-prometheus-alerts.grep.to/rules
```


cd rules

#### CPU
vim cpu.yml
```
groups:
  - name: cpu-alert
    rules:
    - alert: NodeCpuHigh
      expr: (1 - avg by (instance) (irate(node_cpu_seconds_total{job="node-target",mode="idle"}[5m]))) * 100 > 80
      for: 5m
      labels:
        severity: warning
        instance: "{{ $labels.instance }}"
      annotations:
        summary: "instance: {{ $labels.instance }} cpu使用率过高"
        description: "CPU 使用率超过 80%"
        value: "{{ $value }}"

    - alert: NodeCpuIowaitHigh
      expr: avg by (instance) (irate(node_cpu_seconds_total{job="node-target",mode="iowait"}[5m])) * 100 > 50
      for: 5m
      labels:
        severity: warning
        instance: "{{ $labels.instance }}"
      annotations:
        summary: "instance: {{ $labels.instance }} cpu iowait 使用率过高"
        description: "CPU iowait 使用率超过 50%"
        value: "{{ $value }}"

    - alert: NodeLoad5High
      expr: node_load5 > (count by (instance) (node_cpu_seconds_total{job="node-target",mode='system'})) * 1.2
      for: 5m
      labels:
        severity: warning
        instance: "{{ $labels.instance }}"
      annotations:
        summary: "instance: {{ $labels.instance }} load(5m) 过高"
        description: "Load(5m) 过高，超出cpu核数 1.2倍"
        value: "{{ $value }}"
```

#### disk
vim disk.yml
```
groups:
  - name: node-alert
    rules:
    - alert: NodeDiskHigh
      expr: ceil(((node_filesystem_size_bytes {device=~"(/dev/.*|/)",fstype=~"(ext4|xfs)"} - node_filesystem_free_bytes {device=~"(/dev/.*|/)",fstype=~"(ext4|xfs)"}) / node_filesystem_size_bytes {device=~"(/dev/.*|/)",fstype=~"(ext4|xfs)"} ) * 100  > 80 )
      for: 10m
      labels:
        severity: warning
        instance: "{{ $labels.instance }}"
      annotations:
        summary: "instance: {{ $labels.instance }} disk( {{ $labels.mountpoint }} 分区) 使用率过高"
        description: "Disk( {{ $labels.mountpoint }} 分区) 使用率超过 80%"
        value: "{{ $value }}"
```

#### mem
vim mem.yml
```
groups:
  - name: memory-alert
    rules:
    - alert: NodeMemoryHigh
      expr: (1 - node_memory_MemAvailable_bytes{job="node"} / node_memory_MemTotal_bytes{job="node"}) * 100 > 90
      for: 5m
      labels:
        severity: warning
        instance: "{{ $labels.instance }}"
      annotations:
        summary: "instance: {{ $labels.instance }} memory 使用率过高"
        description: "Memory 使用率超过 90%"
        value: "{{ $value }}"
```

#### node
vim node.yml
```
groups:
  - name: node-alert
    rules:
    - alert: NodeDown5m
      expr: up{job="node"} == 0
      for: 5m
      labels:
        severity: critical
        instance: "{{ $labels.instance }}"
      annotations:
        summary: "instance: {{ $labels.instance }} down"
        description: "Instance: {{ $labels.instance }} 已经宕机 5分钟"
        value: "{{ $value }}"
    - alert: NodeDown30m
      expr: up{job="node"} == 0
      for: 30m
      labels:
        severity: critical
        instance: "{{ $labels.instance }}"
      annotations:
        summary: "instance: {{ $labels.instance }} down"
        description: "Instance: {{ $labels.instance }} 已经宕机 30分钟"
        value: "{{ $value }}"
```

### 添加 targets

#### 创建目录
```
mkdir jmx jvm node prjectVer website
```

#### jmx 配置
cd jmx
vim target.yml
```
# edibz
- targets: ['47.112.97.170:20101']
  labels: {cluster: 'wms',type: 'jmx',project: 'edibz',env: 'prod',job: 'edibz10401',export: 'jmx',ip: '47.112.97.170'}
- targets: ['47.112.97.170:20102']
  labels: {cluster: 'wms',type: 'jmx',project: 'edibz',env: 'prod',job: 'edibz10402',export: 'jmx',ip: '47.112.97.170'}


# ediqm
- targets: ['47.112.125.246:20201']
  labels: {cluster: 'wms',type: 'jmx',project: 'ediqm',env: 'prod',job: 'ediqm10200',export: 'jmx',ip: '47.112.125.246'}
- targets: ['47.112.125.246:20202']
  labels: {cluster: 'wms',type: 'jmx',project: 'ediqm',env: 'prod',job: 'ediqm10201',export: 'jmx',ip: '47.112.125.246'}
- targets: ['47.112.118.67:20203']
  labels: {cluster: 'wms',type: 'jmx',project: 'ediqm',env: 'prod',job: 'ediqm10202',export: 'jmx',ip: '47.112.118.67'}
- targets: ['47.112.118.67:20204']
  labels: {cluster: 'wms',type: 'jmx',project: 'ediqm',env: 'prod',job: 'ediqm10203',export: 'jmx',ip: '47.112.118.67'}


# wms
- targets: ['47.112.98.225:20001']
  labels: {cluster: 'wms',type: 'jmx',project: 'xwms',env: 'prod',job: 'xwms10000',export: 'jmx',ip: '47.112.98.225'}
- targets: ['47.112.119.2:20002']
  labels: {cluster: 'wms',type: 'jmx',project: 'xwms',env: 'prod',job: 'xwms10002',export: 'jmx',ip: '47.112.119.2'}
- targets: ['47.112.115.7:20003']
  labels: {cluster: 'wms',type: 'jmx',project: 'xwms',env: 'prod',job: 'xwms10003',export: 'jmx',ip: '47.112.115.7'}
- targets: ['47.112.125.15:20004']
  labels: {cluster: 'wms',type: 'jmx',project: 'xwms',env: 'prod',job: 'xwms10004',export: 'jmx',ip: '47.112.125.15'}
#- targets: ['47.112.169.38:20005']
#  labels: {cluster: 'wms',type: 'jmx',project: 'xwms',env: 'prod',job: 'xwms10005',export: 'jmx',ip: '47.112.169.38'}
```

#### node 配置文件
```
mkdir bigdata  bms  dba  jingtian  oa  xwms  yunpei  zms  zop
```
cd xwms
```
- targets: ['47.107.233.112:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-nginx-api-01","ip": "47.107.233.112"}
- targets: ['47.112.114.10:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-nginx-web-01","ip": "47.112.114.10"}
- targets: ['47.112.98.225:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-wms-01","ip": "47.112.98.225"}
- targets: ['47.112.119.2:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-wms-02","ip": "47.112.119.2"}
- targets: ['47.112.115.7:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-wms-03","ip": "47.112.115.7"}
- targets: ['47.112.125.15:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-wms-04","ip": "47.112.125.15"}
- targets: ['47.112.125.246:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-qm-01","ip": "47.112.125.246"}
- targets: ['47.112.118.67:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-qm-02","ip": "47.112.118.67"}
- targets: ['47.112.97.170:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-bz-01","ip": "47.112.97.170"}
- targets: ['47.112.138.225:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-express-01","ip": "47.112.138.225"}
- targets: ['47.112.116.45:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-express-02","ip": "47.112.116.45"}
- targets: ['47.112.125.154:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-id-01","ip": "47.112.125.154"}
- targets: ['47.112.123.210:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-schedule-01","ip": "47.112.123.210"}
- targets: ['47.112.106.181:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-schedule-02","ip": "47.112.106.181"}
- targets: ['120.79.163.136:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-cluster-schedule-03","ip": "120.79.163.136"}
- targets: ['47.112.153.226:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-web-pre-01","ip": "47.112.153.226"}
- targets: ['47.112.119.25:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-api-pre-01","ip": "47.112.119.25"}
- targets: ['47.112.147.64:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-web-pre-02","ip": "47.112.147.64"}
- targets: ['47.112.117.33:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-api-pre-02","ip": "47.112.117.33"}
- targets: ['47.112.169.38:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-web-pre-03","ip": "47.112.169.38"}
- targets: ['120.77.181.215:6301']
  labels: {"project": "xwms","env": "prod","hostname": "ali02-prod-wms-api-pre-03","ip": "120.77.181.215"}
```


#### targets 添加脚本
vim add.sh
```
#!/bin/bash
env="prod"
project="bigdata"

cat /dev/null > target.yml
while read line;
do
if [[ $line =~ ^# ]];then
  continue
fi
  tip=`echo $line | cut -f 1 -d " "`
  thost=`echo $line | cut -f 2 -d " "`
  echo $tip .. $thost
if  [ ! -n "$tip" ] ;then
  echo "you have not input a word!"
  continue
fi
cat >>target.yml<<-EOF
- targets: ['${tip}:6301']
  labels: {"project": "${project}","env": "${env}","hostname": "${thost}","ip": "${tip}"}

EOF
done<hostname
```


vim hostname
```
172.16.104.200  cdh.ops.com
172.16.104.201  cdh01.ops.com
172.16.104.202  cdh02.ops.com
172.16.104.203  cdh03.ops.com
172.16.104.204  cdh04.ops.com
172.16.104.205  cdh05.ops.com
172.16.104.206  cdh06.ops.com
172.16.104.207  cdh07.ops.com
172.16.104.208  cdh08.ops.com
172.16.104.209  cdh09.ops.com
47.115.21.93    ali02-prod-bi-box-01.ops.com
47.115.17.67    ali02-prod-bi-box-02.ops.com
#172.16.105.116  hz01-prod-bi-haizao-01.ops.com
#172.16.105.119  hz01-prod-bi-haizao-02.ops.com
```