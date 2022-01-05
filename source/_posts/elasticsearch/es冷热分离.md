---
title: es7实现数据自动冷热分离
date: 2021-12-16 09:42
categories:
- elasticsearch
tags:
- es
---
  
  
摘要: es7 实现数据自动冷热分离
<!-- more -->

### 冷热数据分离的目的
在基于时序数据中，我们总是关心最近产生的数据，例如查询订单通常只会查询最近三天，至多到最近一个月的，查询日志也是同样的情形，很少会去查询历史数据，也就是说类似的时序数据随着时间推移，价值在逐渐弱化。在es中经常按日或按月建立索引，我们很容易想到，历史索引被查询命中的概率越来越低，不应该占用高性能的机器资源(比如大内存，SSD)，可以将其迁移到低配置的机器上，从而实现冷热数据分离存储。

通俗解读：热节点存放用户最关心的热数据；温节点或者冷节点存放用户不太关心或者关心优先级低的冷数据或者暖数据。

### 典型应用场景

一句话：在成本有限的前提下，让客户关注的实时数据和历史数据硬件隔离，最大化解决客户反应的响应时间慢的问题。

业务场景描述：
每日增量6TB日志数据，高峰时段写入及查询频率都较高，集群压力较大，查询ES时，常出现查询缓慢问题。

    ES集群的索引写入及查询速度主要依赖于磁盘的IO速度，冷热数据分离的关键为使用SSD磁盘存储热数据，提升查询效率。
    若全部使用SSD，成本过高，且存放冷数据较为浪费，因而使用普通SATA磁盘与SSD磁盘混搭，可做到资源充分利用，性能大幅提升的目标。


###  冷热数据分离的前提
1、ES 的索引已经按照天或者月的时间维度生成索引。

2、历史数据相对于近期数据来说没有高频度的查询需求。


### 分片分配规则(shard allocation filtering)

有四个es节点，2台高性能机器(hot)和2个低配置机器(warm)，通常索引分片会均匀分布在集群节点中，但我们希望最新的数据由于其写入和查询频繁的特性，只能保存在hot节点上，而过期的数据保存在warm节点上，30天过后自动删除。

实现该功能，首先要对节点人为的打个标签，然后在索引创建时指定要把分片分配给hot节点，在索引不再写入后，迁移到warm节点上


#### 三节点架构
资源有限

分片 2

副本 0

|IP|功能|
|---|---|
|192.168.10.10|master,hot|
|192.168.10.11|node,hot|
|192.168.10.12|node，cold|
|192.168.10.13|node，cold|



### 节点tag

依次启动三个节点，同时加入box_type和resource_level标签，box_type标记node1、node2为warm节点，node3为hot节点，resource_level标记机器资源的性能，分为高，中，低
```
启动命令配置

bin/elasticsearch -d -p pid -E node.name=node1 -E node.max_local_storage_nodes=3 -E path.data=node1_data -E path.logs=node1_logs -E node.attr.box_type=warm -E node.attr.resource_level=high

bin/elasticsearch -d -p pid -E node.name=node2 -E node.max_local_storage_nodes=3 -E path.data=node2_data -E path.logs=node2_logs -E node.attr.box_type=warm -E node.attr.resource_level=mdeium

bin/elasticsearch -d -p pid -E node.name=node3 -E node.max_local_storage_nodes=3 -E path.data=node3_data -E path.logs=node3_logs -E node.attr.box_type=hot -E node.attr.resource_level=high

```

配置文件
```
hot

###########################################################################  10

#ES集群名.每个节点需要定义同一个集群名
cluster.name: es
node.name: hz01-prod-ops-elastic-01.ops.com
path.data: /ztocwst/elasticsearch-7.0.1/data
path.logs: /ztocwst/elasticsearch-7.0.1/logs

#绑定IP.本机的内网IP
network.host: 192.168.10.10

#集群内其他ES节点地址
discovery.seed_hosts: ["hz01-prod-ops-elastic-01.ops.com", "hz01-prod-ops-elastic-02.ops.com","hz01-prod-ops-elastic-03.ops.com"]
#初始化master节点,#master节点分布在不同的物理服务器
cluster.initial_master_nodes: ["hz01-prod-ops-elastic-01.ops.com", "hz01-prod-ops-elastic-02.ops.com","hz01-prod-ops-elastic-03.ops.com"]

#是否需要锁定内存,不适应swap虚拟内存
bootstrap.memory_lock: true

#添加属性,标志位热节点.如果是冷节点,该值为cold
node.attr.box_type: cold
node.attr.rack: r1
# es 默认每个节点都有所有的角色，在冷节点总将 data_hot 去除，在热节点总将 data_cold 去除
node.roles: [master,data,data_content,data_hot,data_warm,data_frozen,ingest,ml,remote_cluster_client,transform]

## xpack
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
xpack.ml.enabled: true
xpack.license.self_generated.type: trial
xpack.monitoring.collection.enabled: true

## 内存限制
indices.memory.index_buffer_size: 20%
indices.memory.min_index_buffer_size: 96mb

#磁盘水位线
cluster.routing.allocation.disk.watermark.low: 85%
cluster.routing.allocation.disk.watermark.high: 90%

#用于 fielddata 的最大内存，如果 fielddata 达到该阈值，就会把旧数据交换出去。该参数可以设置百分比或者绝对值。默认设置是不限制，所#以强烈建议设置该值
indices.fielddata.cache.size: 10%

#limit值需要大于indices.fielddata.cache.size的值。否则的话fielddata大小一到limit阈值就报错,就永远道不了size阈值,无法触发对##旧数据的交换任务
indices.breaker.fielddata.limit: 30%


#######################################################################  11

#ES集群名.每个节点需要定义同一个集群名
cluster.name: es
node.name: hz01-prod-ops-elastic-01.ops.com
path.data: /ztocwst/elasticsearch-7.0.1/data
path.logs: /ztocwst/elasticsearch-7.0.1/logs

#绑定IP.本机的内网IP
network.host: 192.168.10.11

#集群内其他ES节点地址
discovery.seed_hosts: ["hz01-prod-ops-elastic-01.ops.com", "hz01-prod-ops-elastic-02.ops.com","hz01-prod-ops-elastic-03.ops.com"]
#初始化master节点,#master节点分布在不同的物理服务器
cluster.initial_master_nodes: ["hz01-prod-ops-elastic-01.ops.com", "hz01-prod-ops-elastic-02.ops.com","hz01-prod-ops-elastic-03.ops.com"]


#是否需要锁定内存,不适应swap虚拟内存
bootstrap.memory_lock: true

#添加属性,标志位热节点.如果是冷节点,该值为cold
node.attr.box_type: hot
node.attr.rack: r1
# es 默认每个节点都有所有的角色，在冷节点总将 data_hot 去除，在热节点总将 data_cold 去除
node.roles: [master,data,data_content,data_hot,data_warm,data_frozen,ingest,ml,remote_cluster_client,transform]


## xpack
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
xpack.ml.enabled: true
xpack.license.self_generated.type: trial
xpack.monitoring.collection.enabled: true

## 内存限制
indices.memory.index_buffer_size: 20%
indices.memory.min_index_buffer_size: 96mb

#磁盘水位线
cluster.routing.allocation.disk.watermark.low: 85%
cluster.routing.allocation.disk.watermark.high: 90%

#用于 fielddata 的最大内存，如果 fielddata 达到该阈值，就会把旧数据交换出去。该参数可以设置百分比或者绝对值。默认设置是不限制，所#以强烈建议设置该值
indices.fielddata.cache.size: 10%

#limit值需要大于indices.fielddata.cache.size的值。否则的话fielddata大小一到limit阈值就报错,就永远道不了size阈值,无法触发对##旧数据的交换任务
indices.breaker.fielddata.limit: 30%
```

```
cold


#######################################################################  12

#ES集群名.每个节点需要定义同一个集群名
cluster.name: es
node.name: hz01-prod-ops-elastic-01.ops.com
path.data: /ztocwst/elasticsearch-7.0.1/data
path.logs: /ztocwst/elasticsearch-7.0.1/logs

#绑定IP.本机的内网IP
network.host: 192.168.10.12

#集群内其他ES节点地址
discovery.seed_hosts: ["hz01-prod-ops-elastic-01.ops.com", "hz01-prod-ops-elastic-02.ops.com","hz01-prod-ops-elastic-03.ops.com"]
#初始化master节点,#master节点分布在不同的物理服务器
cluster.initial_master_nodes: ["hz01-prod-ops-elastic-01.ops.com", "hz01-prod-ops-elastic-02.ops.com","hz01-prod-ops-elastic-03.ops.com"]


#是否需要锁定内存,不适应swap虚拟内存
bootstrap.memory_lock: true

#添加属性,标志位热节点.如果是冷节点,该值为cold
node.attr.box_type: cold
node.attr.rack: r9
# es 默认每个节点都有所有的角色，在冷节点总将 data_hot 去除，在热节点总将 data_cold 去除
node.roles: [master,data,data_content,data_warm,data_cold,data_frozen,ingest,ml,remote_cluster_client,transform]


## xpack
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
xpack.ml.enabled: true
xpack.license.self_generated.type: trial
xpack.monitoring.collection.enabled: true

## 内存限制
indices.memory.index_buffer_size: 20%
indices.memory.min_index_buffer_size: 96mb

#磁盘水位线
cluster.routing.allocation.disk.watermark.low: 85%
cluster.routing.allocation.disk.watermark.high: 90%

#用于 fielddata 的最大内存，如果 fielddata 达到该阈值，就会把旧数据交换出去。该参数可以设置百分比或者绝对值。默认设置是不限制，所#以强烈建议设置该值
indices.fielddata.cache.size: 10%

#limit值需要大于indices.fielddata.cache.size的值。否则的话fielddata大小一到limit阈值就报错,就永远道不了size阈值,无法触发对##旧数据的交换任务
indices.breaker.fielddata.limit: 30%


#######################################################################  13
#ES集群名.每个节点需要定义同一个集群名
cluster.name: es
node.name: hz01-prod-ops-elastic-01.ops.com
path.data: /ztocwst/elasticsearch-7.0.1/data
path.logs: /ztocwst/elasticsearch-7.0.1/logs

#绑定IP.本机的内网IP
network.host: 192.168.10.13

#集群内其他ES节点地址
discovery.seed_hosts: ["hz01-prod-ops-elastic-01.ops.com", "hz01-prod-ops-elastic-02.ops.com","hz01-prod-ops-elastic-03.ops.com"]
#初始化master节点,#master节点分布在不同的物理服务器
cluster.initial_master_nodes: ["hz01-prod-ops-elastic-01.ops.com", "hz01-prod-ops-elastic-02.ops.com","hz01-prod-ops-elastic-03.ops.com"]


#是否需要锁定内存,不适应swap虚拟内存
bootstrap.memory_lock: true

#添加属性,标志位热节点.如果是冷节点,该值为cold
node.attr.box_type: cold
node.attr.rack: r9
# es 默认每个节点都有所有的角色，在冷节点总将 data_hot 去除，在热节点总将 data_cold 去除
node.roles: [master,data,data_content,data_warm,data_cold,data_frozen,ingest,ml,remote_cluster_client,transform]

## xpack
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
xpack.ml.enabled: true
xpack.license.self_generated.type: trial
xpack.monitoring.collection.enabled: true

## 内存限制
indices.memory.index_buffer_size: 20%
indices.memory.min_index_buffer_size: 96mb

#磁盘水位线
cluster.routing.allocation.disk.watermark.low: 85%
cluster.routing.allocation.disk.watermark.high: 90%

#用于 fielddata 的最大内存，如果 fielddata 达到该阈值，就会把旧数据交换出去。该参数可以设置百分比或者绝对值。默认设置是不限制，所#以强烈建议设置该值
indices.fielddata.cache.size: 10%

#limit值需要大于indices.fielddata.cache.size的值。否则的话fielddata大小一到limit阈值就报错,就永远道不了size阈值,无法触发对##旧数据的交换任务
indices.breaker.fielddata.limit: 30%

```



### 查看属性

kibana中输入以下命令
```
GET _cat/indices?v

```

得到以下结果，可以看到box_type和resource_level标签在每个节点的值
```
node  host      ip        attr              value
node3 127.0.0.1 127.0.0.1 ml.machine_memory 17179869184
node3 127.0.0.1 127.0.0.1 ml.max_open_jobs  20
node3 127.0.0.1 127.0.0.1 box_type          hot
node3 127.0.0.1 127.0.0.1 xpack.installed   true
node3 127.0.0.1 127.0.0.1 resource_level    high
node1 127.0.0.1 127.0.0.1 ml.machine_memory 17179869184
node1 127.0.0.1 127.0.0.1 box_type          warm
node1 127.0.0.1 127.0.0.1 xpack.installed   true
node1 127.0.0.1 127.0.0.1 ml.max_open_jobs  20
node1 127.0.0.1 127.0.0.1 resource_level    high
node2 127.0.0.1 127.0.0.1 ml.machine_memory 17179869184
node2 127.0.0.1 127.0.0.1 ml.max_open_jobs  20
```

### 建立声明周期
例子
```
PUT _ilm/policy/my_policy
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            //rollover前距离索引的创建时间最大为1小时
            "max_age": "1h",
            //rollover前索引的最大大小不超过50G
            "max_size": "50G",
            //rollover前索引的最大文档数不超过2个
            "max_docs": 2,
          }
        }
      },
      "warm": {
        //rollover之后进入warm阶段的时间不小于2小时
        "min_age": "2h",
        "actions": {
          "forcemerge": {
            //强制分片merge到segment为1
            "max_num_segments": 1
          },
          "shrink": {
            //收缩分片数为1
            "number_of_shards": 1
          },
          "allocate": {
            //副本数为1
            "number_of_replicas": 1
          }
        }
      },
      "cold": {
        //rollover之后进入cold阶段的时间不小于3小时
        "min_age": "3h",
        "actions": {
          "allocate": {
            "require": {
              //分配到cold 节点，ES可根据机器资源配置不同类型的节点
              "type": "cold"
            }
          }
        }
      },
      "delete": {
        //rollover之后进入cold阶段的时间不小于4小时
        "min_age": "4小时",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```
创建一个声明周期，2天后转冷数据，90天后自动删除
```
PUT _ilm/policy/logs_policy
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {}
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {
            "delete_searchable_snapshot" : true
          }
        }
      },
      "warm": {
        "min_age": "2d",
        "actions": {
          "allocate": {
            "include": {},
            "exclude": {},
            "require": {
              "box_type": "cold"
            }
          }
        }
      }
    }
  }
}
```

查看声明周期
```
GET _ilm/policy/logs_policy
```


### 建立索引模板

```
{
  "order": 0,
  "index_patterns": [
    "log_*"
  ],
  "settings": {
    "index": {
      "lifecycle": {
        "name": "logs_policy"
      },
      "routing": {
        "allocation": {
          "require": {
            "box_type": "hot"
          }
        }
      },
      "number_of_shards": "2",
      "number_of_replicas": "0"
    }
  },
  "mappings": {}
}
```
手动应用生命周期策略

```
PUT test-index
{
    "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 1,
        "index.lifecycle.name": "logs_policy"
    }
}
```
将策略应用于多个索引
```
PUT test-index-*/_settings
{
    "index": {
        "lifecycle": {
            "name": "logs_policy"
        }
    }
}

```


