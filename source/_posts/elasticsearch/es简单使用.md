---
title: elasticsearch简单使用
date: 2021-12-16 10:45
categories:
- elasticsearch
tags:
- es
---
  
  
摘要: elasticsearch简单使用
<!-- more -->

## 模板

#### 创建模板
```
POST /_template/order_id_template
{
  "script": {
    "lang": "mustache",
    "source": {
      "query": {
        "match": {
          "order_id": "{{orderId}}"
        }
      }
    }
  }
}
```

#### 删除模板
```
DELETE  /_template/order_id_template
```

#### 查看所有模板
```
GET /_cat/templates?pretty
```

#### 查看某个模板
```
GET /_template/situation-sw_test-template?pretty
```

#### 查看所有mapping
```
GET /_mapping?pretty
```

#### 查看某个mapping
```
GET /situation-sw_test*/_mapping?pretty
```

#### 修改模板
```
PUT /_index_template/template_1
```


## Cat命令

### aliases
显示别名,过滤器,路由信息
```
GET _cat/aliases?v

alias               index                          filter routing.index routing.search is_write_index
goods_order 		goods_order_2020-01-25 -      -             -              -
```
|返回字段	|原文|	含义|
|---|---|---|
|alias	|alias name	|别名|
|index	|index alias points to|	索引别名指向|
|filter	|filter	|过滤器|
|routing.index|	index routing|	索引路由|
|routing.search	|search routing	|搜索路由|
|is_write_index	|write index	|写索引|


### allocation
显示每个节点分片数量、占用空间
```
GET _cat/allocation?v

shards disk.indices disk.used disk.avail disk.total disk.percent host          ip            node
    70      431.6mb     8.9gb    130.2gb    139.2gb            6 10.61.149.206 10.61.149.206 10.61.149.206
    70        442mb       9gb    130.1gb    139.2gb            6 10.61.149.199 10.61.149.199 10.61.149.199
```

|返回字段	|原文	|含义|
|---|---|---|
|shards	|number of shards on node	|节点承载的分片数量|
|disk.indices |	disk used by ES indices	|索引占用的空间大小|
|disk.used|	disk used (total, not just ES)|	节点所在机器已使用的磁盘空间大下|
|disk.avail|	disk available|	节点可用空间大小|
|disk.total|	total capacity of all volumes|	节点总空间大小|
|disk.percent|	percent disk used	|节点磁盘占用百分比|
|host	|host of node	|节点host|
|ip	|ip of node	|节点ip|
|node|	name of node|	节点名称|


### count
显示索引文档的数量
```
GET _cat/count?v

epoch      timestamp count
1585051390 12:03:10  2815367
```

|返回字段	|原文	|含义|
|---|---|---|
|epoch|	seconds since 1970-01-01 00:00:00	|自标准时间（1970-01-01 00:00:00）以来的秒数|
|timestamp	|time in HH:MM:SS	|时分秒,utc时区|
|count|	the document count	|文档总数|

### health
查看集群健康状况
```
GET _cat/health?v

epoch      timestamp cluster                   status node.total node.data shards pri relo init unassign pending_tasks max_task_wait_time active_shards_percent
1585051499 12:04:59	order-common green           2         2    140 136    0    0        0             0                  -                100.0%
```
|返回字段	|原文	|含义|
|---|---|---|
|epoch|	seconds since 1970-01-01 00:00:00	|自标准时间（1970-01-01 00:00:00）以来的秒数|
|timestamp|	time in HH:MM:SS	|时分秒,utc时区|
|cluster	|cluster name	|集群名称|
|status|	health status|	集群状态|
|node.total	|total number of nodes|	节点总数|
|node.data|	number of nodes that can store data|	数据节点总数|
|shards	|total number of shards	|分片总数|
|pri|	number of primary shards|	主分片总数|
|relo|	number of relocating nodes	|复制节点总数|
|init	|number of initializing nodes	|初始化节点总数|
|unassign|	number of unassigned shards|	未分配分片总数|
|pending_tasks	|number of pending tasks|	待定任务总数|
|max_task_wait_time	|wait time of longest task pending |等待最长任务的等待时间|
|active_shards_percent|	active number of shards in percent|活动分片百分比|


### indices
查看索引信息
```
GET _cat/indices?v

health status index                          uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   goods_order_2020-02-24		 A4Q8pyv1QR2wfw5jmqQQuw   2   0      98187        75798     15.5mb         15.5mb
```

|返回字段|	原文|	含义|
|---|---|---|
|health|	current health status|	索引健康状态|
|status	|open/close status	|索引的开启状态|
|index|	index name|	索引名称|
|uuid|	index uuid	|索引uuid|
|pri|	number of primary shards|	索引主分片数|
|rep|	number of replica shards	|索引副本分片数量|
|docs.count|	available docs|	索引中文档总数|
|docs.deleted	|deleted docs|	索引中删除状态的文档|
|store.size|	store size of primaries & replicas|	主分片+副本分片的大小|
|pri.store.size|	store size of primaries	|主分片的大小|


### master
显示master节点信息
```
GET _cat/master?v

id                     host          ip            node
hgbRZIBNSoyCcb3E15dlNA 10.61.149.199 10.61.149.199 10.61.149.199
```

|返回字段|	原文	|含义|
|---|---|---|
|id	|node id	|节点id|
|host	|host name|	host|
|ip	|ip address	|ip|
|node|	node name|	节点名称|


### nodeattrs
显示node节点属性
```
GET _cat/nodeattrs?v

node          host          ip            attr              value
10.61.149.199 10.61.149.199 10.61.149.199 ml.machine_memory 25112244224
10.61.149.199 10.61.149.199 10.61.149.199 ml.max_open_jobs  20
10.61.149.199 10.61.149.199 10.61.149.199 xpack.installed   true
10.61.149.206 10.61.149.206 10.61.149.206 ml.machine_memory 25112244224
10.61.149.206 10.61.149.206 10.61.149.206 ml.max_open_jobs  20
10.61.149.206 10.61.149.206 10.61.149.206 xpack.installed   true
```

|返回字段|	原文|	含义|
|---|---|---|
|node	|node name|	节点名称|
|host	|host name|	host|
|ip	|ip address	|ip|
|attr	|attribute description|	属性描述|
|value|	attribute value|	属性值|


### nodes
显示node节点信息
```
GET _cat/nodes?v

ip            heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
10.61.149.206           32          69   0    0.00    0.02     0.05 dilm      -      10.61.149.206
10.61.149.199           54          67   0    0.00    0.01     0.05 dilm      *      10.61.149.199
```

|返回字段	|原文	|含义|
|---|---|---|
|id|	unique node id|	ip|
|heap.percent	|used heap|	堆内存占用百分比|
|ram.percent|	used machine memory ratio|	内存占用百分比|
|cpu|	recent cpu|	CPU占用百分比|
|load_1m|	1m load avg	|1分钟的系统负载|
|load_5m|	5m load avg	|5分钟的系统负载|
|load_15m	|15m load avg	|15分钟的系统负载|
|node.role|	m:master eligible node, d:data node, i:ingest node, -:coordinating node only	|node节点的角色
|master	|*:current master|	是否是master节点|
|name	|node name	|节点名称|


### pending_tasks
显示正在等待的任务
```
GET _cat/pending_tasks?v

insertOrder timeInQueue priority source

```

|返回字段|	原文	|含义|
|---|---|---|
|insertOrder|	task insertion order|	任务插入顺序|
|timeInQueue|	how long task has been in queue|	任务排队了多长时间|
|priority	|task priority|	任务优先级|
|source	|task source|	任务源|


### plugins
显示节点上的插件
```
GET _cat/plugins?v

name         component       version
10.25.237.34 analysis-ik     7.4.2
10.25.237.34 analysis-pinyin 7.4.2
10.25.237.33 analysis-ik     7.4.2
10.25.237.33 analysis-pinyin 7.4.2
```

|返回字段|	原文|	含义|
|---|---|---|
|name	|node name|	节点名称|
|component|	component|	插件名称|
|version|	component version|	插件版本|



### recovery
显示正在进行和先前完成的索引碎片恢复的视图
```
GET _cat/recovery?v

index                          shard time  type           stage source_host  source_node  target_host  target_node  repository snapshot files files_recovered files_percent files_total bytes bytes_recovered bytes_percent bytes_total translog_ops translog_ops_recovered translog_ops_percent
goods_order_2020-02-24			0     25ms  existing_store done  n/a          n/a          10.25.237.34 10.25.237.34 n/a        n/a      0     0               100.0%        24          0     0               100.0%        8069221     0            0                      100.0%

```

|返回字段|	原文	|含义|
|---|---|---|
|index|	index name|	索引名称|
|shard|	shard name|	分片名称|
|time	|recovery time|	恢复时间|
|type	|recovery type|	恢复类型|
|stage|	recovery stage|	恢复阶段|
|source_host|	source host	|源主机|
|source_node|	source node name|	源节点名称|
|target_host|	target host	|目标主机|
|target_node|	target node name|	目标节点名称|
|repository	|repository|	仓库|
|snapshot	|snapshot|	快照|
|files|	number of files to recover|	要恢复的文件数|
|files_recovered	|files recovered	|已恢复的文件数|
|files_percent	|percent of files recovered	|恢复文件百分比|
|files_total|	total number of files|	文件总数|
|bytes|	number of bytes to recover|	要恢复的字节数|
|bytes_recovered|	bytes recovered	|已恢复的字节数|
|bytes_percent|	percent of bytes recovered|	恢复字节百分比|
|bytes_total|	total number of bytes	|字节总数|
|translog_ops|	number of translog ops to recover|	要恢复的translog操作数|
|translog_ops_recovered	|translog ops recovered|	已恢复的|translog操作数|
|translog_ops_percent	|percent of translog ops recovered|	恢复的translog操作的百分比|



### segments
显示分片中的分段信息
```
GET _cat/segments?v

index                          shard prirep ip           segment generation docs.count docs.deleted    size size.memory committed searchable version compound
goods_order_2020-02-24 			0     p      10.25.237.34 _8a            298      45938        35933   7.2mb       12113 true      true       8.2.0   false

```

|返回字段	|原文	|含义|
|---|---|---|
|index	|index name	|索引名称|
|shard	|shard name|	分片名称|
|prirep|	primary or replica	|主分片还是副本分片|
|ip|	ip of node where it lives|	所在节点ip|
|segment|	segment name|	segments段名|
|generation	|segment generation|	分段生成|
|docs.count|	number of docs in segment	|段中的文档数|
|docs.deleted	|number of deleted docs in segment|	段中删除的文档数|
|size	|segment size in bytes |段大小，以字节为单位|
|size.memory|	segment memory in bytes|	段内存大小，以字节为单位|
|committed|	is segment committed|	段是否已提交|
|searchable|	is segment searched|	段是否可搜索|
|version|	version|	版本|
|compound|	is segment compound	|compound模式|


### shards
显示索引分片信息
```
GET _cat/shards?v

index                          shard prirep state     docs  store ip           node
goods_order_2020-03-04 			1     p      STARTED  42301  6.1mb 10.25.237.33 10.25.237.33

```

|返回字段|	原文|	含义|
|---|---|---|
|index	|index name	|索引名称|
|shard|	shard name|	分片序号|
|prirep|	primary or replica|	分片类型，p表示是主分片，r表示是复制分片|
|state|	shard state	|分片状态|
|docs	|number of docs in shard|	该分片存放的文档数量|
|store	|store size of shard (how much disk it uses)|	该分片占用的存储空间大小|
|ip	|ip of node where it lives|	该分片所在的服务器ip|
|node	|name of node where it|	该分片所在的节点名称|




### thread_pool
显示线程池信息
```
GET _cat/thread_pool?v

node_name     name                active queue rejected
10.61.149.206 analyze                  0     0        0
10.61.149.206 ccr                      0     0        0
```

|返回字段|	原文|	含义|
|---|---|---|
|node_name|	node name|	节点名称|
|name	|thread pool name|	线程池名称|
|active|	number of active threads |活跃线程数|
|queue	|number of tasks currently in queue|	当前队列中的任务数|
|rejected	|number of rejected tasks|	被拒绝的任务数|



### templates
显示模板信息
```
GET _cat/templates?v

name                        index_patterns                order      version
.monitoring-es              [.monitoring-es-7-*]          0          7000199
.data-frame-internal-2      [.data-frame-internal-2]      0          7040299
```

|返回字段	|原文	|含义|
|---|---|---|
|name	|template name|	模板名称|
|index_patterns	template index patterns|	模板匹配规则|
|order|	template application order number	|模板优先级|
|version|	version	|模板版本|



### 额外
```
GET _cat/health
```
### v显示表头
```
GET _cat/allocation?v
```

### help显示命令返回的参数说明
```
GET _cat/allocation?help
```
### h选择要显示的列
```
GET _cat/health?v&h=epoch,cluster
```

### format设置返回的内容格式
支持json,yaml,text,smile,cbor
```
GET _cat/health?format=json
```

### sort排序
```
GET _cat/indices?v&s=docs.count:desc,store.size:asc
```

### 可以多个参数一起使用，用&连接
```
GET _cat/indices?v&s=store.size:desc
```
