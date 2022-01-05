---
title: es7.1升级到7.8
date: 2021-12-17 14:17
categories:
- elasticsearch
tags:
- es
---
  
  
摘要: es7.1升级到7.8
<!-- more -->

## 数据备份
## 数据备份
## 数据备份

从官网下载最新的安装包，将下载的文件放到我们的服务器上解压备用，记得顺便更新下系统。
```
https://www.elastic.co/cn/downloads/elasticsearch

https://www.elastic.co/cn/downloads/kibana
```

如果破解x-pack, 记得把破解好的包替换了。
```
modules/x-pack-core/x-pack-core-7.0.1.jar
```

将下载后的文件解压缩到指定的目录，提前将配置文件配置好。这里简单记录下我修改的配置文件的内容。 对于elasticsearch的配置文件在config目录里主要修改elasticsearch.yml。
```
cluster.name: es
node.name: hz01-prod-ops-elastic-01.ops.com
path.data: /ztocwst/elasticsearch-7.0.1/data
path.logs: /ztocwst/elasticsearch-7.0.1/logs
network.host: 10.200.92.48
discovery.seed_hosts: ["hz01-prod-ops-elastic-01.ops.com", "hz01-prod-ops-elastic-02.ops.com","hz01-prod-ops-elastic-03.ops.com"]
cluster.initial_master_nodes: ["hz01-prod-ops-elastic-01.ops.com", "hz01-prod-ops-elastic-02.ops.com","hz01-prod-ops-elastic-03.ops.com"]
bootstrap.memory_lock: true
node.attr.box_type: cold
node.attr.rack: r9
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
xpack.ml.enabled: true
xpack.license.self_generated.type: trial
xpack.monitoring.collection.enabled: true
indices.memory.index_buffer_size: 20%
indices.memory.min_index_buffer_size: 96mb
cluster.routing.allocation.disk.watermark.low: 85%
cluster.routing.allocation.disk.watermark.high: 90%
indices.fielddata.cache.size: 10%
indices.breaker.fielddata.limit: 30%
```


开始升级

本次目标是从7.1升级到7.8，小版本升级，内容比较简单。

首先我们先关闭写入es数据的程序然后关闭ES集群的shard allocation功能：

```
PUT _cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.enable": "primaries"
  }
}
```

使用下面的命令确保数据全部写入到了磁盘中：

```
POST _flush/synced
```

如果有机器学习任务，记得也关闭下，然后停止我们老的ES程序，接下来开启新的ES程序。

注意我这里是直接下载程序包运行的，由于ES无法运行在root上，我们需要给我们的程序设置好权限。然后以我们制定的用户运行

```
chown -R elsearch:elsearch
```

4、恢复

    首先我们先检查节点，确定节点都已经上线运行。

```
GET _cat/nodes
```

开启ES集群的shard allocation功能：

```
PUT _cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.enable": null
  }
}
```

然后我们检查集群的状态，确定所有索引都恢复为绿色。

```
GET _cat/health?v
```

最后将关系的写入程序启动

