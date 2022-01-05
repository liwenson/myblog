---
title: es配置详解和优化
date: 2021-12-16 11:20
categories:
- elasticsearch
tags:
- es
---
  
  
摘要: es配置详解和优化
<!-- more -->


### 优化

es的安装和配置是非常轻量级的，为满足多种不同的应用场景，底层提供多种数据结构支持，并做了大量的默认配置优化，部分配置针对具体的用户使用场景可能是冗余的，甚至可能造成性能的下降，需要根据实际业务场景做适当取舍，我们结合自身使用场景做了如下优化（文章中有疏漏或不正确的地方也欢迎点评指正）。

### 一、环境配置

```
sudo swapoff -a
# 禁用swapping，开启服务器虚拟内存交换功能会对es产生致命的打击
vm.max_map_count
# 在/etc/sysctl.conf文件中找到该参数，修改为655300后 执行sysctl -p，不然启动时会报值太小
```

### 二、内存优化

常用的配置在两个文件里，分别是 elasticsearch.yml 和 jvm.options（配置内存）

jvm.options主要是进行内存相关配置，elasticsearch默认给的1g，官方建议分配给es的内存不要超出系统内存的50%，预留一半给Lucene，因为Lucene会缓存segment数据提升检索性能；内存配置不要超过32g，如果你的服务器内存没有远远超过64g，那么不建议将es的jvm内存设置为32g，因为超过32g后每个jvm对象指针的长度会翻倍，导致内存与cpu的开销增大。

```
-Xms10g
-Xmx10g
```

### 三、基础配置
修改配置文件elasticsearch.yml
```
cluster.name: elasticsearch
集群名称，es服务会通过广播方式自动连接在同一网段下的es服务，通过多播方式进行通信，同一网段下可以有多个集群，通过集群名称这个属性来区分不同的集群。

node.name: "test"
当前配置所在机器的节点名，你不设置就默认随机指定一个name列表中名字，该name列表在es的jar包中config文件夹里name.txt文件中，其中有很多作者添加的有趣名字。

node.master: true
指定该节点是否有资格被选举成为node（注意这里只是设置成有资格， 不代表该node一定就是master），默认是true，es是默认集群中的第一台机器为master，如果这台机挂了就会重新选举master。

node.data: true
指定该节点是否存储索引数据，默认为true。

index.number_of_shards: 5
设置默认索引分片个数，默认为5片。

index.number_of_replicas: 1
设置默认索引副本个数，默认为1个副本。如果采用默认设置，而你集群只配置了一台机器，那么集群的健康度为yellow，也就是所有的数据都是可用的，但是某些复制没有被分配。

path.conf: /path/to/conf
设置配置文件的存储路径，默认是es根目录下的config文件夹。

path.data: /path/to/data
设置索引数据的存储路径，默认是es根目录下的data文件夹，可以设置多个存储路径，用逗号隔开，例：path.data: /path/to/data1,/path/to/data2

path.work: /path/to/work
设置临时文件的存储路径，默认是es根目录下的work文件夹。

path.logs: /path/to/logs
设置日志文件的存储路径，默认是es根目录下的logs文件夹

path.plugins: /path/to/plugins
设置插件的存放路径，默认是es根目录下的plugins文件夹, 插件在es里面普遍使用，用来增强原系统核心功能。

bootstrap.mlockall: true
设置为true来锁住内存不进行swapping。因为当jvm开始swapping时es的效率 会降低，所以要保证它不swap，可以把ES_MIN_MEM和ES_MAX_MEM两个环境变量设置成同一个值，并且保证机器有足够的内存分配给es。 同时也要允许elasticsearch的进程可以锁住内存，linux下启动es之前可以通过`ulimit -l unlimited`命令设置。

network.bind_host: 192.168.0.1
设置绑定的ip地址，可以是ipv4或ipv6的，默认为127.0.0.1。

network.publish_host: 192.168.0.1
设置其它节点和该节点交互的ip地址，如果不设置它会自动判断，值必须是个真实的ip地址。

network.host: 192.168.0.1
这个参数是用来同时设置bind_host和publish_host上面两个参数。

transport.tcp.port: 9300
设置节点之间交互的tcp端口，默认是9300。

transport.tcp.compress: true
设置是否压缩tcp传输时的数据，默认为false，不压缩。

http.port: 9200
设置对外服务的http端口，默认为9200。

http.max_content_length: 100mb
设置内容的最大容量，默认100mb

http.enabled: false
是否使用http协议对外提供服务，默认为true，开启。

gateway.type: local
gateway的类型，默认为local即为本地文件系统，可以设置为本地文件系统，分布式文件系统，hadoop的HDFS，和amazon的s3服务器等。

gateway.recover_after_nodes: 1
设置集群中N个节点启动时进行数据恢复，默认为1。

gateway.recover_after_time: 5m
设置初始化数据恢复进程的超时时间，默认是5分钟。

gateway.expected_nodes: 2
设置这个集群中节点的数量，默认为2，一旦这N个节点启动，就会立即进行数据恢复。

cluster.routing.allocation.node_initial_primaries_recoveries: 4
初始化数据恢复时，并发恢复线程的个数，默认为4。

cluster.routing.allocation.node_concurrent_recoveries: 2
添加删除节点或负载均衡时并发恢复线程的个数，默认为4。

indices.recovery.max_size_per_sec: 0
设置数据恢复时限制的带宽，如入100mb，默认为0，即无限制。

indices.recovery.concurrent_streams: 5
设置这个参数来限制从其它分片恢复数据时最大同时打开并发流的个数，默认为5。

discovery.zen.minimum_master_nodes: 1
设置这个参数来保证集群中的节点可以知道其它N个有master资格的节点。默认为1，对于大的集群来说，可以设置大一点的值（2-4）

discovery.zen.ping.timeout: 3s
设置集群中自动发现其它节点时ping连接超时时间，默认为3秒，对于比较差的网络环境可以高点的值来防止自动发现时出错。

discovery.zen.ping.multicast.enabled: false
设置是否打开多播发现节点，默认是true。

discovery.zen.ping.unicast.hosts: ["host1", "host2:port", "host3[portX-portY]"]
设置集群中master节点的初始列表，可以通过这些节点来自动发现新加入集群的节点。
```

### 三、集群优化

```
1、集群规划优化实践
1.1 基于目标数据量规划集群
在业务初期，经常被问到的问题，要几个节点的集群，内存、CPU要多大，要不要SSD？
最主要的考虑点是：你的目标存储数据量是多大？可以针对目标数据量反推节点多少。

1.2 要留出容量Buffer
注意：Elasticsearch有三个警戒水位线，磁盘使用率达到85%、90%、95%。
不同警戒水位线会有不同的应急处理策略。
这点，磁盘容量选型中要规划在内。控制在85%之下是合理的。
当然，也可以通过配置做调整。

1.3 ES集群各节点尽量不要和其他业务功能复用一台机器。
除非内存非常大。
举例：普通服务器，安装了ES+Mysql+redis，业务数据量大了之后，势必会出现内存不足等问题。

1.4 磁盘尽量选择SSD
Elasticsearch官方文档肯定推荐SSD，考虑到成本的原因。需要结合业务场景，
如果业务对写入、检索速率有较高的速率要求，建议使用SSD磁盘。
阿里的业务场景，SSD磁盘比机械硬盘的速率提升了5倍。
但要因业务场景而异。

1.5 内存配置要合理
官方建议：堆内存的大小是官方建议是：Min（32GB，机器内存大小/2）。
Medcl和wood大叔都有明确说过，不必要设置32/31GB那么大，建议：热数据设置：26GB，冷数据：31GB。
总体内存大小没有具体要求，但肯定是内容越大，检索性能越好。
经验值供参考：每天200GB+增量数据的业务场景，服务器至少要64GB内存。
除了JVM之外的预留内存要充足，否则也会经常OOM。

1.6 CPU核数不要太小
CPU核数是和ESThread pool关联的。和写入、检索性能都有关联。
建议：16核+。

1.7 超大量级的业务场景，可以考虑跨集群检索
除非业务量级非常大，例如：滴滴、携程的PB+的业务场景，否则基本不太需要跨集群检索。

1.8 集群节点个数无需奇数
ES内部维护集群通信，不是基于zookeeper的分发部署机制，所以，无需奇数。
但是discovery.zen.minimum_master_nodes的值要设置为：候选主节点的个数/2+1，才能有效避免脑裂。

1.9 节点类型优化分配
集群节点数：<=3，建议：所有节点的master：true， data：true。既是主节点也是路由节点。
集群节点数：>3, 根据业务场景需要，建议：逐步独立出Master节点和协调/路由节点。

1.10 建议冷热数据分离
热数据存储SSD和普通历史数据存储机械磁盘，物理上提高检索效率。

2、索引优化实践
Mysql等关系型数据库要分库、分表。Elasticserach的话也要做好充分的考虑。

2.1 设置多少个索引？
建议根据业务场景进行存储。
不同通道类型的数据要分索引存储。举例：知乎采集信息存储到知乎索引；APP采集信息存储到APP索引。

2.2 设置多少分片？
建议根据数据量衡量。
经验值：建议每个分片大小不要超过30GB。

2.3 分片数设置？
建议根据集群节点的个数规模，分片个数建议>=集群节点的个数。
5节点的集群，5个分片就比较合理。
注意：除非reindex操作，分片数是不可以修改的。

2.4副本数设置？
除非你对系统的健壮性有异常高的要求，比如：银行系统。可以考虑2个副本以上。
否则，1个副本足够。
注意：副本数是可以通过配置随时修改的。

2.5不要再在一个索引下创建多个type
即便你是5.X版本，考虑到未来版本升级等后续的可扩展性。
建议：一个索引对应一个type。6.x默认对应_doc，5.x你就直接对应type统一为doc。

2.6 按照日期规划索引
随着业务量的增加，单一索引和数据量激增给的矛盾凸显。
按照日期规划索引是必然选择。
好处1：可以实现历史数据秒删。很对历史索引delete即可。注意：一个索引的话需要借助delete_by_query+force_merge操作，慢且删除不彻底。
好处2：便于冷热数据分开管理，检索最近几天的数据，直接物理上指定对应日期的索引，速度快的一逼！
操作参考：模板使用+rollover API使用。

2.7 务必使用别名
ES不像mysql方面的更改索引名称。使用别名就是一个相对灵活的选择。

3、数据模型优化实践
3.1 不要使用默认的Mapping
默认Mapping的字段类型是系统自动识别的。其中：string类型默认分成：text和keyword两种类型。如果你的业务中不需要分词、检索，仅需要精确匹配，仅设置为keyword即可。
根据业务需要选择合适的类型，有利于节省空间和提升精度，如：浮点型的选择。

3.2 Mapping各字段的选型流程
在这里插入图片描述

3.3 选择合理的分词器
常见的开源中文分词器包括：ik分词器、ansj分词器、hanlp分词器、结巴分词器、海量分词器、“ElasticSearch最全分词器比较及使用方法” 搜索可查看对比效果。
如果选择ik，建议使用ik_max_word。因为：粗粒度的分词结果基本包含细粒度ik_smart的结果。

3.4 date、long、还是keyword
根据业务需要，如果需要基于时间轴做分析，必须date类型；
如果仅需要秒级返回，建议使用keyword。

4、数据写入优化实践
4.1 要不要秒级响应？
Elasticsearch近实时的本质是：最快1s写入的数据可以被查询到。
如果refresh_interval设置为1s，势必会产生大量的segment，检索性能会受到影响。
所以，非实时的场景可以调大，设置为30s，甚至-1。

4.2 减少副本，提升写入性能。
写入前，副本数设置为0，
写入后，副本数设置为原来值。

4.3 能批量就不单条写入
批量接口为bulk，批量的大小要结合队列的大小，而队列大小和线程池大小、机器的cpu核数。

4.4 禁用swap
在Linux系统上，通过运行以下命令临时禁用交换：

sudo swapoff -a
1
5、检索聚合优化实战
5.1 禁用 wildcard模糊匹配
数据量级达到TB+甚至更高之后，wildcard在多字段组合的情况下很容易出现卡死，甚至导致集群节点崩溃宕机的情况。
后果不堪设想。
替代方案：
方案一：针对精确度要求高的方案:两套分词器结合，standard和ik结合，使用match_phrase检索。
方案二：针对精确度要求不高的替代方案：建议ik分词，通过match_phrase和slop结合查询。

5.2极小的概率使用match匹配
中文match匹配显然结果是不准确的。很大的业务场景会使用短语匹配“match_phrase"。
match_phrase结合合理的分词词典、词库，会使得搜索结果精确度更高，避免噪音数据。

5.3 结合业务场景，大量使用filter过滤器
对于不需要使用计算相关度评分的场景，无疑filter缓存机制会使得检索更快。
举例：过滤某邮编号码。

5.3控制返回字段和结果
和mysql查询一样，业务开发中，select * 操作几乎是不必须的。
同理，ES中，_source 返回全部字段也是非必须的。
要通过_source 控制字段的返回，只返回业务相关的字段。
网页正文content，网页快照html_content类似字段的批量返回，可能就是业务上的设计缺陷。
显然，摘要字段应该提前写入，而不是查询content后再截取处理。

5.4 分页深度查询和遍历
分页查询使用：from+size;
遍历使用：scroll；
并行遍历使用：scroll+slice。
斟酌集合业务选型使用。

5.5 聚合Size的合理设置
聚合结果是不精确的。除非你设置size为2的32次幂-1，否则聚合的结果是取每个分片的Top size元素后综合排序后的值。
实际业务场景要求精确反馈结果的要注意。
尽量不要获取全量聚合结果——从业务层面取TopN聚合结果值是非常合理的。因为的确排序靠后的结果值意义不大。

5.6 聚合分页合理实现
聚合结果展示的时，势必面临聚合后分页的问题，而ES官方基于性能原因不支持聚合后分页。
如果需要聚合后分页，需要自开发实现。包含但不限于：
方案一：每次取聚合结果，拿到内存中分页返回。
方案二：scroll结合scroll after集合redis实现。
```