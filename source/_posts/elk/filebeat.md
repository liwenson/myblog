---
title: filebeat 使用
date: 2021-07-05 14:09
categories:
- elk
tags:
- filebeat
- elk
---
	
	
摘要: filebeat 使用
<!-- more -->


# filebeat 使用

## 一、前言
这里使用的7.7.0版本，在官方文档快速上手的中，只要简单配置了filelbeat.yml ，启动filebeat就可以收集日志了。

```
# 定义输入
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
# 定义输出
output.elasticsearch:
  hosts: ["myEShost:9200"]
  username: "filebeat_internal"
  password: "YOUR_PASSWORD" 
setup.kibana:
  host: "mykibanahost:5601"
  username: "my_kibana_user"  
  password: "YOUR_PASSWORD"
```

其实filebeat提供的可配置项有很多，这里就以大模块角度了解下其分类。 更多详细内容，[点击查看官网](https://www.elastic.co/guide/en/beats/filebeat/7.7/index.html)。


## 二、参数配置分类

### 1、 Paths
用于定义Filebeat查找相关文件的位置。例如，Filebeat在config路径中查找启动文件，并在log路径中写入日志文件。Filebeat在data路径中查找其registry文件。

用户可以不配置，使用默认的路径。也可以自定义配置路径：
```
path.home: /usr/share/filebeat
path.config: /etc/filebeat
path.data: /var/lib/filebeat
path.logs: /var/log/
```


```
#================================= Paths ======================================

# The home path for the Filebeat installation. This is the default base path
# for all other path settings and for miscellaneous files that come with the
# distribution (for example, the sample dashboards).
# If not set by a CLI flag or in the configuration file, the default for the
# home path is the location of the binary.
#path.home:

# The configuration path for the Filebeat installation. This is the default
# base path for configuration files, including the main YAML configuration file
# and the Elasticsearch template file. If not set by a CLI flag or in the
# configuration file, the default for the configuration path is the home path.
#path.config: ${path.home}

# The data path for the Filebeat installation. This is the default base path
# for all the files in which Filebeat needs to store its data. If not set by a
# CLI flag or in the configuration file, the default for the data path is a data
# subdirectory inside the home path.
#path.data: ${path.home}/data

# The logs path for a Filebeat installation. This is the default location for
# the Beat's log files. If not set by a CLI flag or in the configuration file,
# the default for the logs path is a logs subdirectory inside the home path.
#path.logs: ${path.home}/logs
```

#### 配置参数说明
```
1、path.home
Filebeat安装的主路径。这是所有其他路径设置和发行版附带的其他文件（例如，示例仪表板）的默认基本路径。如果未设置，则主路径的默认值是Filebeat二进制文件的位置。

2、path.config
Filebeat安装的配置路径。这是配置文件的默认基本路径，包括主YAML配置文件和Elasticsearch模板文件。如果设置，则配置路径的默认值为{path.home}路径。

3、path.data
Filebeat的数据路径。这是Filebeat需要存储其数据的所有文件的默认基本路径。如果设置，则数据路径的默认值是{path.home}/data。

注意： 每个filebeat实例的path.data必须是唯一的。

4、path.log
Filebeat的日志路径。这是Filebeat日志文件的默认位置。如果未设置，则日志路径的默认值为{path.home}/log。
```

#### 默认启动时的路径
比如说用户在 /home/abc/work 路径下启动filebeat，那么path.home 就默认为 当前路径。并且可以看到 多了两个文件夹data和 log




### 2、Modules configuration
Filebeat模块简化了常见日志格式的收集、解析和可视化。典型的模块（比如Nginx日志）由一个或多个文件集组成（对于Nginx，是access和error），如果你启用了下面的module, fileabeat就可以根据系统自动去寻找access、error 对应的log文件进行收集。
```
- module: nginx
  # Access logs
  #access:
    #enabled: true

    # Set custom paths for the log files. If left empty,
    # Filebeat will choose the paths depending on your OS.
    #var.paths:

    # Input configuration (advanced). Any input configuration option
    # can be added under this section.
    #input:
```

Filebeat会根据您的环境自动调整这些配置，并将它们加载到相应的Elastic stack组件中

配置文件的方式：
```
filebeat.config:
  modules:
    # 通过这里开启， 默认是关闭
    enabled: true
    path: modules.d/*.yml
    reload.enabled: true
    reload.period: 10s

```


### 3、Filebeat inputs
如果你想手动配置Filebeat（而不是使用模块），可以在配置文件filebeat.inputs部分设置Filebeat采集源以及相关参数配置。每个输入源都以破折号（-）开头。用户可以指定多个输入源，并且可以多次指定同一输入类型。例如：
```
filebeat.inputs:
- type: log
  paths:
    - /var/log/system.log
    - /var/log/wifi.log
- type: log
  paths:
    - "/var/log/apache2/*"
  fields:
    apache: true
  fields_under_root: true
- type: tcp
  max_message_size: 10MiB
  host: "localhost:9000"
```
点击查看更多input 配置

### 4、Filebeat autodiscover
在容器上运行应用程序时，它们会成为监视系统的移动目标。“自动发现”允许您跟踪它们并在更改发生时调整设置。通过定义配置模板，自动发现子系统可以在服务开始运行时监视它们。
```
filebeat.autodiscover:
  List of enabled autodiscover providers
 providers:
   - type: docker
     templates:
       - condition:
           equals.docker.container.image: busybox
         config:
           - type: container
             paths:
               - /var/lib/docker/containers/${data.docker.container.id}/*.log
```

### 5、Filebeat global options
定义publisher行为或者某些文件的位置信息，这些参数是filebeat根节点参数。比如register文件路径、或者是否启用modules、多个inputs等等
```
# Registry data path. If a relative path is used, it is considered relative to the
# data path.
#filebeat.registry.path: ${path.data}/registry

# The permissions mask to apply on registry data, and meta files. The default
# value is 0600.  Must be a valid Unix-style file permissions mask expressed in
# octal notation.  This option is not supported on Windows.
#filebeat.registry.file_permissions: 0600

# The timeout value that controls when registry entries are written to disk
# (flushed). When an unwritten update exceeds this value, it triggers a write
# to disk. When flush is set to 0s, the registry is written to disk after each
# batch of events has been published successfully. The default value is 0s.
#filebeat.registry.flush: 0s


# Starting with Filebeat 7.0, the registry uses a new directory format to store
# Filebeat state. After you upgrade, Filebeat will automatically migrate a 6.x
# registry file to use the new directory format. If you changed
# filebeat.registry.path while upgrading, set filebeat.registry.migrate_file to
# point to the old registry file.
#filebeat.registry.migrate_file: ${path.data}/registry

# By default Ingest pipelines are not updated if a pipeline with the same ID
# already exists. If this option is enabled Filebeat overwrites pipelines
# everytime a new Elasticsearch connection is established.
#filebeat.overwrite_pipelines: false

# How long filebeat waits on shutdown for the publisher to finish.
# Default is 0, not waiting.
#filebeat.shutdown_timeout: 0

# Enable filebeat config reloading
#filebeat.config:
  #inputs:
    #enabled: false
    #path: inputs.d/*.yml
    #reload.enabled: true
    #reload.period: 10s
  #modules:
    #enabled: false
    #path: modules.d/*.yml
    #reload.enabled: true
    #reload.period: 10s
```

#### 相关参数说明
registry文件夹里记录了filebeat当前采集文件的元信息（包含文件名、读取的offset、文件id等等）

1、filebeat.registry.path
如果不设置，默认路径是${path.data}/registry ，一般不设置 。

2、filebeat.registry.file_permissions
registry文件操作权限码，默认是0600 ，如果没有特殊需求 使用默认值即可。注意：在windows上不支持此参数。

3、filebeat.registry.flush
默认值为0. 表示 当filebeat成功发送了采集的数据，立即刷新registry 。 用户可以合理设置刷新间隔， 减轻IO压力。

4、filebeat.registry.migrate_file
迁移文件路径： 从7.0后，registry存储方式和6.x的不一样。 如果你以前使用的是6.x版本的filebeat，然后想更新到7.x ，并且想沿用以前的registry信息，那么你可以使用这个参数：
```
filebeat.registry.path: ${path.data}/registry
filebeat.registry.migrate_file: /path/to/old/registry_file
```
5、filebeat.shutdown_timeout
Filebeat在关闭之前等待发布者完成发送事件的时间，然后Filebeat关闭。不建议设置该参数，因为确定shutdown_timeout的正确值很大程度上取决于Filebeat运行的环境以及输出的当前状态。

6、filebeat.config
可选配置 是否启动modules
```
filebeat.config:
  #modules:
    #enabled: false
    #path: modules.d/*.yml
    #reload.enabled: true
    #reload.period: 10s
```
如果你想在一个配置文件filebeat.yml里想采集复杂的多个log文件或者复杂输入源，你可以开启下面的配置（），然后自定义多个输入源文件即可。
```
filebeat.config:
  inputs:
    enabled: true
    path: inputs.d/*.yml
    reload.enabled: true
    reload.period: 10s
```


### 6、General
所有Elastic Beats都支持这些选项。因为它们是通用选项，所以它们没有命名空间
```
#================================ General ======================================

# The name of the shipper that publishes the network data. It can be used to group
# all the transactions sent by a single shipper in the web interface.
# If this options is not defined, the hostname is used.
#name:

# The tags of the shipper are included in their own field with each
# transaction published. Tags make it easy to group servers by different
# logical properties.
#tags: ["service-X", "web-tier"]

# Optional fields that you can specify to add additional information to the
# output. Fields can be scalar values, arrays, dictionaries, or any nested
# combination of these.
#fields:
#  env: staging

# If this option is set to true, the custom fields are stored as top-level
# fields in the output document instead of being grouped under a fields
# sub-dictionary. Default is false.
#fields_under_root: false

# Internal queue configuration for buffering events to be published.
#queue:
  # Queue type by name (default 'mem')
  # The memory queue will present all available events (up to the outputs
  # bulk_max_size) to the output, the moment the output is ready to server
  # another batch of events.
  #mem:
    # Max number of events the queue can buffer.
    #events: 4096

    # Hints the minimum number of events stored in the queue,
    # before providing a batch of events to the outputs.
    # The default value is set to 2048.
    # A value of 0 ensures events are immediately available
    # to be sent to the outputs.
    #flush.min_events: 2048

    # Maximum duration after which events are available to the outputs,
    # if the number of events stored in the queue is < `flush.min_events`.
    #flush.timeout: 1s

  # The spool queue will store events in a local spool file, before
  # forwarding the events to the outputs.
  #
  # Beta: spooling to disk is currently a beta feature. Use with care.
  #
  # The spool file is a circular buffer, which blocks once the file/buffer is full.
  # Events are put into a write buffer and flushed once the write buffer
  # is full or the flush_timeout is triggered.
  # Once ACKed by the output, events are removed immediately from the queue,
  # making space for new events to be persisted.
  #spool:
    # The file namespace configures the file path and the file creation settings.
    # Once the file exists, the `size`, `page_size` and `prealloc` settings
    # will have no more effect.
    #file:
      # Location of spool file. The default value is ${path.data}/spool.dat.
      #path: "${path.data}/spool.dat"

      # Configure file permissions if file is created. The default value is 0600.
      #permissions: 0600

      # File size hint. The spool blocks, once this limit is reached. The default value is 100 MiB.
      #size: 100MiB

      # The files page size. A file is split into multiple pages of the same size. The default value is 4KiB.
      #page_size: 4KiB

      # If prealloc is set, the required space for the file is reserved using
      # truncate. The default value is true.
      #prealloc: true

    # Spool writer settings
    # Events are serialized into a write buffer. The write buffer is flushed if:
    # - The buffer limit has been reached.
    # - The configured limit of buffered events is reached.
    # - The flush timeout is triggered.
    #write:
      # Sets the write buffer size.
      #buffer_size: 1MiB

      # Maximum duration after which events are flushed if the write buffer
      # is not full yet. The default value is 1s.
      #flush.timeout: 1s

      # Number of maximum buffered events. The write buffer is flushed once the
      # limit is reached.
      #flush.events: 16384

      # Configure the on-disk event encoding. The encoding can be changed
      # between restarts.
      # Valid encodings are: json, ubjson, and cbor.
      #codec: cbor
    #read:
      # Reader flush timeout, waiting for more events to become available, so
      # to fill a complete batch as required by the outputs.
      # If flush_timeout is 0, all available events are forwarded to the
      # outputs immediately.
      # The default value is 0s.
      #flush.timeout: 0s

# Sets the maximum number of CPUs that can be executing simultaneously. The
# default is the number of logical CPUs available in the system.
#max_procs:
```

#### 参数说明
1、name
默认是用服务器的主机名。该名称以agent.name字段而存在。

2、tag
为采集的日志消息定义tag信息标识，用于接收端处理响应的逻辑。
```
tags: ["web-service","info-file"]
```
3、fields
定义额外的字段信息，定义的字段以KV形式出现。默认是在fields下。

fields: {project: "credit", env: "prod"}
1
如果设置了fields_under_root为true，那么自定义的KV 将作为根字段出现在发送的消息里。

4、fields_under_root
自定义的字段是否作为根字段。 使用实例
```
fields_under_root: true
fields: {project: "credit", env: "prod"}
```
5、processors
beat提供的数据预处理 功能，如果定义了多个processors ，那么beat将会顺序执行。 更多定义的processor

6、max_procs
设置可以同时执行的最大CPU数。默认值为系统中可用的逻辑CPU的数量。


### 7、 Processors
beat提供的数据预处理 功能，用于增强数据或者过滤数据。如果定义了多个processors ，那么beat将会顺序执行
```
event -> processor 1 -> event1 -> processor 2 -> event2 ...
```


1、add_cloud_metadata
添加云服务器实例元数据

增加云服务器提供商的实例元数据来丰富每个事件。在启动时，它将查询托管提供程序的列表并缓存实例元数据。

例如添加上这个配置
```
processors:
  - add_cloud_metadata: ~
```
在阿里云上输出为
```
{
  "cloud": {
    "availability_zone": "cn-shenzhen",
    "instance.id": "i-wz9g2hqiikg0aliyun2b",
    "provider": "ecs",
    "region": "cn-shenzhen-a"
  }
}
```
在腾讯云上输出为
```
{
  "cloud": {
    "availability_zone": "gz-azone2",
    "instance.id": "ins-qcloudv5",
    "provider": "qcloud",
    "region": "china-south-gz"
  }
}
```
在aws上输出为
```
{
  "cloud": {
    "account.id": "123456789012",
    "availability_zone": "us-east-1c",
    "instance.id": "i-4e123456",
    "machine.type": "t2.medium",
    "image.id": "ami-abcd1234",
    "provider": "aws",
    "region": "us-east-1"
  }
}
```

2、add_cloudfoundry_metadata
自动添加cloudfoundry应用程序的相关元数据

该处理器使用来自cloudfoundry应用程序的相关元数据对每个事件进行增强。

前提条件：只有当事件包含对CloudFoundry应用程序的引用（使用字段cloudfoundry.app.id)，并且配置了cloudfoundry客户端信息，才能能够检索应用程序的信息。

配置示例：

```
processors:
  - add_cloudfoundry_metadata:
      api_address: https://api.dev.cfdev.sh
      client_id: uaa-filebeat
      client_secret: verysecret
      ssl:
        verification_mode: none
      # To connect to Cloud Foundry over verified TLS you can specify a client and CA certificate.
      #ssl:
      #  certificate_authorities: ["/etc/pki/cf/ca.pem"]
      #  certificate:              "/etc/pki/cf/cert.pem"
      #  key:                      "/etc/pki/cf/cert.key"
```


3、add_docker_metadata
自动添加docker容器相关元数据

filebeat在启动时，它检测一个docker环境元数据并缓存。只有在检测到有效配置并且处理器能够访问Docker API时，才会使用Docker元数据对事件数据进行追加。 目前在k8s场景下 一般使用log-pilot来协助采集日志。
```
processors:
  - add_docker_metadata:
      host: "unix:///var/run/docker.sock"
      #match_fields: ["system.process.cgroup.id"]
      #match_pids: ["process.pid", "process.ppid"]
      #match_source: true
      #match_source_index: 4
      #match_short_id: true
      #cleanup_timeout: 60
      #labels.dedot: false
      # To connect to Docker over TLS you must specify a client and CA certificate.
      #ssl:
      #  certificate_authority: "/etc/pki/root/ca.pem"
      #  certificate:           "/etc/pki/client/cert.pem"
      #  key:                   "/etc/pki/client/cert.key"
```

4、add_fields

添加自定义字段信息

添加字段信息（同这里用法类似），配置如下
```
processors:
  - add_fields:
      #  如果不指定，默认添加到 fields 里 
      target: project
      fields:
        name: myproject
        id: '574734885120952459'
```
输出为：
```
{
  "project": {
    "name": "myproject",
    "id": "574734885120952459"
  }
}
```

5、add_host_metadata

自动追加host相关信息，配置如下
```
processors:
  - add_host_metadata:
      cache.ttl: 5m
      geo:
        name: nyc-dc1-rack1
        location: 40.7128, -74.0060
        continent_name: North America
        country_iso_code: US
        region_name: New York
        region_iso_code: NY
        city_name: New York
```
结果为
```
{
   "host":{
      "architecture":"x86_64",
      "name":"example-host",
      "id":"",
      "os":{
         "family":"darwin",
         "build":"16G1212",
         "platform":"darwin",
         "version":"10.12.6",
         "kernel":"16.7.0",
         "name":"Mac OS X"
      },
      "ip": ["192.168.0.1", "10.0.0.1"],
      "mac": ["00:25:96:12:34:56", "72:00:06:ff:79:f1"],
      "geo": {
          "continent_name": "North America",
          "country_iso_code": "US",
          "region_name": "New York",
          "region_iso_code": "NY",
          "city_name": "New York",
          "name": "nyc-dc1-rack1",
          "location": "40.7128, -74.0060"
        }
   }
}
```


6、add_id

根据envet生成唯一的ID

自动追加 根据envet生成唯一的ID

配置如下：
```
processors:
  - add_id: ~
```
输出为：
```
"@metadata": {                                                                                                                     
    "beat": "filebeat",                                                                                                              
    "type": "_doc",                                                                                                                  
    "version": "7.7.0",                                                                                                              
    "_id": "jfXPVHQB95_6f7tCZ5hg"                                                                                                    
},
```

7、add_kubernetes_metadata
该处理器使用相关元数据对每个事件进行注释，基于kubernetes pod生成事件的元数据。在启动时，它会检测到集群内的环境并缓存Kubernetes相关的元数据。只有在检测到有效配置时才会对事件进行注释。如果它不能检测到有效的Kubernetes配置，那么事件不会用Kubernetes相关的元数据进行注释。
添加的注释有Pod Name 、Pod UID、Namespace、Labels
```
processors:
  - add_kubernetes_metadata: ~
```

8、add_labels

添加自定义标签，类似add_fileds功能 ，添加的kv输出后默认在labels字段下
```
processors:
  - add_labels:
      labels:
        number: 1
        with.dots: test
        nested:
          with.dots: nested
        array:
          - do
          - re
          - with.field: mi
```
输出：
```
{
  "labels": {
    "number": 1,
    "with.dots": "test",
    "nested.with.dots": "nested",
    "array.0": "do",
    "array.1": "re",
    "array.2.with.field": "mi"
  }
}
```

9、add_locale
自动添加时区信息，常用语国际业务中。
```
processors:
  - add_locale: ~
```
下面的意思是 使用缩写模式 ， 例如国内输出结果为CST
```
processors:
  - add_locale:
      format: abbreviation
```
10、add_observer_metadata
自动添加观察者机器的相关元数据
```
processors:
  - add_observer_metadata:
      cache.ttl: 5m
```
输出为：
```
{
  "observer" : {
    "hostname" : "avce",
    "type" : "heartbeat",
    "vendor" : "elastic",
    "ip" : [
      "192.168.1.251",
      "fe80::64b2:c3ff:fe5b:b974",
    ],
    "mac" : [
      "dc:c1:02:6f:1b:ed",
    ]
  }
}
```
11、add_tags
添加标签，并可指定标签在哪个字段下。

例如：
```
processors:
  - add_tags:
      tags: [web, production]
      target: "environment"
```
输出为：
```
{
  "environment": ["web", "production"]
}
```
12、convert
将event中的某个字段转换为其他类型，例如将字符串转换为整数。
```
processors:
  - convert:
      fields:
        - {from: "src_ip", to: "source.ip", type: "ip"}
        - {from: "src_port", to: "source.port", type: "integer"}
      ignore_missing: true
      fail_on_error: false
```
13、copy_fields
将event中的某个字段的值赋值给另一个字段
```
processors:
  - copy_fields:
      fields:
        - from: message
          to: event.original
      fail_on_error: false
      ignore_missing: true
```
输出：
```
{
  "message": "my-interesting-message",
  "event": {
      "original": "my-interesting-message"
  }
}
```

14、decode_base64_field
base64解码，从一个字段里获取值，解码后赋值给另一个字段。
```
processors:
  - decode_base64_field:
      field:
        from: "message"
        to: "decode"
      ignore_missing: true
      fail_on_error: false
```
15、decode_cef
如果你的日式符合Common Event Format (CEF) 标准，你可以使用它进行解码：
```
processors:
  - rename:
      fields:
        - {from: "message", to: "event.original"}
  - decode_cef:
      field: event.original
```
更多关于cef的介绍

16、decode_csv_fields
解析CSF格式的日志到指定字段，内容为数组。
```
processors:
  - decode_csv_fields:
     # 解析到哪里
      fields:
        message: decoded.csv
      separator: ","
      ignore_missing: false
      overwrite_keys: true
      trim_leading_space: false
      fail_on_error: true
```
17、decode_json_fields
处理对包含JSON字符串的字段进行解码，并将字符串替换为有效的JSON对象。默认是在当前字段替换。
```
processors:
  - decode_json_fields:
      fields: ["field1", "field2", ...]
     # process_array: false
      # max_depth: 1
     # overwrite_keys: false
     # add_error_key: true
```
18、decompress_gzip_field
gzip解压缩，从一个字段值中加压缩到另一个字段中 。 使用场景少。
```
processors:
  - decompress_gzip_field:
      field:
        from: "field1"
        to: "field2"
      ignore_missing: false
      fail_on_error: true
```
感兴趣的可以看下 gzip压缩初探

19、dissect
从某个字段里（默认message）取值，按照tokenizer定义的格式 拆分（切割）数据，并输出到target_prefix 字段里，默认是dissect
```
processors:
  - dissect:
      tokenizer: "%{key1} %{key2}"
      # field: "message"
     # target_prefix: "dissect"
```
如果是这样的log"App01 - WebServer is up and running" ，输出为
```
"service": {
  "name": "App01",
  "status": "WebServer is up and running"
},
```
20、dns
反向解析 根据id查找hostname 。每个processor有自己查询结果的缓存。该processor使用自己的域名服务器，不会查找/etc/hosts ，默认使用/etc/resolv.conf里面的域名服务器。
```
processors:
  - dns:
      type: reverse
      fields:
        source.ip: source.hostname
        destination.ip: destination.hostname
```
fields字段里source.ip是指ip所在的字段，source.hostname是指新值存入的字段。

21、drop_event
丢弃该event，一般要设置特定条件 。

例如 http响应码为200 就不上报event：
```
processors:
  - drop_event:
      when:
        equals:
          http.code: 200
```

22、drop_fields
丢弃（过滤掉）特定字段， 一般防止敏感信息上报，例如ip 、mac地址…
```
processors:
  - drop_fields:
      fields: ["cpu.user", "cpu.system"]
```
23、extract_array

从数组中取值并填充（映射到）指定字段

配置示例：
```
  - add_tags:
      tags: ["127.0.0.1", "114.114.114.114","8080"]
      target: "my_array"
  - extract_array:
      field: my_array
      mappings:
        source.ip: 0
        source.destination.ip: 1
        source.network.transport: 2
      fail_on_error: true
      ignore_missing: false
```


24、fingerprint

根据事件指定字段字段值生成事件的指纹。
```
processors:
  - fingerprint:
      fields: ["field1", "field2", ...]
```

25、include_fields

输出的event里 会包含哪些字段值。@timestamp和type字段会始终出现在event中，即使未在include_fields列表中定义。
```
processors:
  - include_fields:
      when:
        condition
      fields: ["field1", "field2", ...]
```
26、registered_domain
域名注册，识别一个长串域名，转化成一个简短域名 。

比如我有一条日志：
```
https://www.netcn.console.aliyun.com/
```
filebeat配置：
```
processors:
  - registered_domain:
      field: message
      target_field: result.registered_domain
      ignore_missing: true
      ignore_failure: true
```
输出为
```
"result": {
  "registered_domain": "aliyun.com/"
}
```

27、rename

重命名字段

示例： 把host重命名为hostRename
```
processors:
  - rename:
      fields:
        - from: "host"
          to: "hostRename"
      ignore_missing: false
      fail_on_error: true
```

28、script

使用Javascript 处理event ，可以更加灵活的预处理业务

29、timestamp

从字段解析时间戳并将解析结果写入@timestamp（日志采集时间）字段

从某个字段解析时间戳，并将解析结果写入@timestamp中，可以自定义日志采集时间。

配置如下：
```
processors:
   timestamp:
      field: start_time
      layouts:
        - '2006-01-02T15:04:05Z'
        - '2006-01-02T15:04:05.999Z'
      test:
        - '2019-06-22T16:33:51Z'
        - '2019-11-18T04:59:51.123Z'
   drop_fields:
      fields: [start_time]
```

```
layouts 是时间格式，用于格式化start_time里的时间，这个是go语言的时间格式。 类似java中的yyyy-MM-dd HH:mm:ss 。
test 是在filebeat启动时 验证layouts的格式能否格式化 测试时间。
```


30、translate_sid
将Windows安全标识符（SID）转换为帐户名，使用仅限Windows系统。
```
processors:
  - translate_sid:
      field: winlog.event_data.MemberSid
      account_name_target: user.name
      domain_target: user.domain
      ignore_missing: true
      ignore_failure: true
```
31、translate_sid
按照指定大小截取字段值
```
processors:
  - truncate_fields:
    fields:
    - message
    max_characters: 5
    #max_bytes: 128
    fail_on_error: false
    ignore_missing: true
```
32、urldecode
url 解码
```
processors:
  - urldecode:
      fields:
        - from: "field1"
          to: "field2"
      #  - from: "fieldx"
       #  to: "fieldy"
      ignore_missing: false
      fail_on_error: true
```

### Outputs

Elasticsearch


常规配置
```
output.elasticsearch:
  hosts: ["https://es.bingmaning:9200"]
  username: "bingmaning"
  password: "lingshui2008@qq.com"
  index: "%{[fields.log_type]}-%{[agent.version]}-%{+yyyy.MM.dd}"
```
更多配置
```
output.elasticsearch:
  # Boolean flag to enable or disable the output module.
  #enabled: true

  #es地址
  hosts: ["https://es.bingmaning:9200"]

  # 设置压缩级别
  compression_level: 0

  # 是否转义html符号
  escape_html: false

  # 协议，默认http
  protocol: "https"

  # 认证方式一
  api_key: "id:api_key"
  # 认证方式二
  username: "elastic"
  password: "changeme"

  # 通过索引操作在URL中传递的HTTP参数字典
  parameters:
    #param1: value1
    #param2: value2

  # 每个Elasticsearch主机worker数量。  
  worker: 1

  #默认索引 filebeat-YYYY.MM.DD  。 可自定义
  index: "filebeat-%{[agent.version]}-%{+yyyy.MM.dd}"

  # 自定义 pipeline
  pipeline: ""

  # 默认http路径
  path: "/elasticsearch"

  # 自定义http header
  headers:
    X-My-Header: Contents of the header

  # 代理地址
  proxy_url: http://proxy:3128

  # 是否禁用代理 默认false
  proxy_disable: false

  # 尝试特定Elasticsearch索引操作的次数。如果多次重试后，索引操作未成功，事件被丢弃。默认为3。
  max_retries: 3

  # 单个Elasticsearch批量API索引请求中要批量处理的最大事件数
  # The default is 50.
  bulk_max_size: 50

  # 重连 初始等待时间，如果失败会指数值增长。
  backoff.init: 1s

  # 最大等待重连时间。默认60秒
  backoff.max: 60s

  # 请求超时时间
  timeout: 90

  # 使用ssl？
  ssl.enabled: true

  # ssl认证方式，默认为full。 测试时 可以使用 none
  ssl.verification_mode: full

  #可用 tls 版本
  ssl.supported_protocols: [TLSv1.1, TLSv1.2, TLSv1.3]

  # 根证书地址
  ssl.certificate_authorities: ["/etc/pki/root/ca.pem"]

  # 客户端证书
  ssl.certificate: "/etc/pki/client/cert.pem"

  # 客户端密钥
  ssl.key: "/etc/pki/client/cert.key"

  # 密码短语
  ssl.key_passphrase: ''

  # 配置密码套件以用于SSL连接
  ssl.cipher_suites: []

  # 为基于ECDHE的密码套件配置曲线类型
  ssl.curve_types: []

  # 配置支持哪些类型的重新协商。有效选项是 
  # never, once, and freely. 默认是 never.
  ssl.renegotiation: never

  # 配置一个可用于对已验证证书链进行额外验证的pin， 这可以确保使用特定证书来验证信任链。
  # 该pin是SHA-256指纹的base64编码字符串。.
  ssl.ca_sha256: ""

  # 是否支持 Kerberos 
  kerberos.enabled: true

  # Kerberos认证类型： keytab, password.
  kerberos.auth_type: password

  # 密钥表文件的路径。当auth_type设置为keytab时使用。
  kerberos.keytab: /etc/elastic.keytab

  #  Kerberos configuration.
  kerberos.config_path: /etc/krb5.conf

  # Name of the Kerberos user.
  kerberos.username: elastic

  # Kerberos用户的密码。当auth_type设置为password时使用。
  kerberos.password: changeme

  # Kerberos realm.
  kerberos.realm: ELASTIC
```

logstash

常规配置
1、filebeat.yml中配置如下：
```
output.logstash:
  hosts: ["localhost:5044", "localhost:5045"]
  # 开这个参数 需要多个hosts
  loadbalance: true
```

2、logstash-pipeline.conf中配置如下：
```
input {
  beats {
    port => 5044
  }
}
filter{
// 数据的各种处理  
....
}
output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    #  @metadata 解释如下
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}" 
  }
}
```

filebeat详细配置
```
output.logstash:

  enabled: true
  
  hosts: ["localhost:5044"]

  # 每个logstash worker数量。  
  worker: 1

  # 压缩级别
  compression_level: 3

  # 是否转义html符号
  escape_html: false

  #最大链接时间 。 0 代表不启用此功能
  # 不支持async connections
  ttl: 30s

  # 是否需要负载均衡
  loadbalance: false

  # 处理时异步发送到Logstash的批次数
  pipelining: 2

  # 如果启用，在没有没有遇到错误的情况下，则每次仅传输一批事件中的一部分事件 ，直到要发送的事件数量增加到`bulk_max_size`
  slow_start: false

  # 重连时间策略 
  backoff.init: 1s
  backoff.max: 60s

  # 默认索引 一般都会重写
  index: 'filebeat'

  # SOCKS5 proxy server URL
  proxy_url: socks5://user:password@socks5-server:2233

  # 是否启用本地解析器
  proxy_use_local_resolver: false

 # 使用ssl？
  ssl.enabled: true

  # ssl认证方式，默认为full。 测试时 可以使用 none
  ssl.verification_mode: full

  #可用 tls 版本
  ssl.supported_protocols: [TLSv1.1, TLSv1.2, TLSv1.3]

  # 根证书地址
  ssl.certificate_authorities: ["/etc/pki/root/ca.pem"]

  # 客户端证书
  ssl.certificate: "/etc/pki/client/cert.pem"

  # 客户端密钥
  ssl.key: "/etc/pki/client/cert.key"

  # 密码短语
  ssl.key_passphrase: ''

  # 配置密码套件以用于SSL连接
  ssl.cipher_suites: []

  # 为基于ECDHE的密码套件配置曲线类型
  ssl.curve_types: []

  # 配置支持哪些类型的重新协商。有效选项是 
  # never, once, and freely. 默认是 never.
  ssl.renegotiation: never

  # 配置一个可用于对已验证证书链进行额外验证的pin， 这可以确保使用特定证书来验证信任链。
  # 该pin是SHA-256指纹的base64编码字符串。.
  ssl.ca_sha256: ""
  
  # 尝试特定Elasticsearch索引操作的次数。如果多次重试后，索引操作未成功，事件被丢弃。默认为3。
  max_retries: 3
  # 单个Logstash request 最大event数量 default is 2048.
  bulk_max_size: 2048

  # 等待Logstash server响应最大超时时间。默认是 30s.
  timeout: 30s
```


redis
Redis输出将event插入Redis列表或Redis通道。该输出插件与Logstash的Redis输入插件兼容。

常规配置
```
# 采集配置
filebeat.inputs:     #收集日志
- type: log         #类型
  enabled: true     #始终收集
  paths:
    - /etc/log/*.log    
# 输出配置
output.redis:        
  hosts: ["127.0.0.1:6379"]  #输出在redis里
  password: "123456"   #redis认证密码，我没有
  key: "filebeat7.7"       #日志redis的key值
  db: 0                 #redis数据库0
  timeout: 5             #redis链接超时  默认5s
```

所有可配置参数
```
output.redis:
  # Boolean flag to enable or disable the output module.
  enabled: true

  # Configure JSON encoding
  codec.json:
    # Pretty print json event
    pretty: false

    # Configure escaping HTML symbols in strings.
    escape_html: false

  # The list of Redis servers to connect to. If load-balancing is enabled, the
  # events are distributed to the servers in the list. If one server becomes
  # unreachable, the events are distributed to the reachable servers only.
  # The hosts setting supports redis and rediss urls with custom password like
  # redis://:password@localhost:6379.
  hosts: ["localhost:6379"]

  # The name of the Redis list or channel the events are published to. The
  # default is filebeat.
  key: filebeat

  # The password to authenticate to Redis with. The default is no authentication.
  password:

  # The Redis database number where the events are published. The default is 0.
  db: 0

  # The Redis data type to use for publishing events. If the data type is list,
  # the Redis RPUSH command is used. If the data type is channel, the Redis
  # PUBLISH command is used. The default value is list.
  datatype: list

  # The number of workers to use for each host configured to publish events to
  # Redis. Use this setting along with the loadbalance option. For example, if
  # you have 2 hosts and 3 workers, in total 6 workers are started (3 for each
  # host).
  worker: 1

  # If set to true and multiple hosts or workers are configured, the output
  # plugin load balances published events onto all Redis hosts. If set to false,
  # the output plugin sends all events to only one host (determined at random)
  # and will switch to another host if the currently selected one becomes
  # unreachable. The default value is true.
  loadbalance: true

  # The Redis connection timeout in seconds. The default is 5 seconds.
  timeout: 5s

  # The number of times to retry publishing an event after a publishing failure.
  # After the specified number of retries, the events are typically dropped.
  # Some Beats, such as Filebeat, ignore the max_retries setting and retry until
  # all events are published. Set max_retries to a value less than 0 to retry
  # until all events are published. The default is 3.
  max_retries: 3

  # The number of seconds to wait before trying to reconnect to Redis
  # after a network error. After waiting backoff.init seconds, the Beat
  # tries to reconnect. If the attempt fails, the backoff timer is increased
  # exponentially up to backoff.max. After a successful connection, the backoff
  # timer is reset. The default is 1s.
  backoff.init: 1s

  # The maximum number of seconds to wait before attempting to connect to
  # Redis after a network error. The default is 60s.
  backoff.max: 60s

  # The maximum number of events to bulk in a single Redis request or pipeline.
  # The default is 2048.
  bulk_max_size: 2048

  # The URL of the SOCKS5 proxy to use when connecting to the Redis servers. The
  # value must be a URL with a scheme of socks5://.
  proxy_url:

  # This option determines whether Redis hostnames are resolved locally when
  # using a proxy. The default value is false, which means that name resolution
  # occurs on the proxy server.
  proxy_use_local_resolver: false

  # Enable SSL support. SSL is automatically enabled, if any SSL setting is set.
  ssl.enabled: true

  # Configure SSL verification mode. If `none` is configured, all server hosts
  # and certificates will be accepted. In this mode, SSL based connections are
  # susceptible to man-in-the-middle attacks. Use only for testing. Default is
  # `full`.
  ssl.verification_mode: full

  # List of supported/valid TLS versions. By default all TLS versions from 1.1
  # up to 1.3 are enabled.
  ssl.supported_protocols: [TLSv1.1, TLSv1.2, TLSv1.3]

  # Optional SSL configuration options. SSL is off by default.
  # List of root certificates for HTTPS server verifications
  ssl.certificate_authorities: ["/etc/pki/root/ca.pem"]

  # Certificate for SSL client authentication
  ssl.certificate: "/etc/pki/client/cert.pem"

  # Client Certificate Key
  ssl.key: "/etc/pki/client/cert.key"

  # Optional passphrase for decrypting the Certificate Key.
  ssl.key_passphrase: ''

  # Configure cipher suites to be used for SSL connections
  ssl.cipher_suites: []

  # Configure curve types for ECDHE based cipher suites
  ssl.curve_types: []

  # Configure what types of renegotiation are supported. Valid options are
  # never, once, and freely. Default is never.
  ssl.renegotiation: never
```


file

配置filebeat的输出方式为文件， 一般用于测试。

常规配置
```
# 采集配置
filebeat.inputs:     #收集日志
- type: log         #类型
  enabled: true     #始终收集
  paths:
    - /etc/log/*.log    
# 输出配置
output.file:
  path: "/tmp/filebeat"  #  输出路径
  filename: filebeat    # 输出文件名
```

所有可配置参数
```
output.file:
  # Boolean flag to enable or disable the output module.
  enabled: true

  # Configure JSON encoding
  codec.json:
    # Pretty-print JSON event
    pretty: false

    # Configure escaping HTML symbols in strings.
    escape_html: false

  # Path to the directory where to save the generated files. The option is
  # mandatory.
  path: "/tmp/filebeat"

  # Name of the generated files. The default is `filebeat` and it generates
  # files: `filebeat`, `filebeat.1`, `filebeat.2`, etc.
  filename: filebeat

  # Maximum size in kilobytes of each file. When this size is reached, and on
  # every Filebeat restart, the files are rotated. The default value is 10240
  # kB.
  rotate_every_kb: 10000

  # Maximum number of files under path. When this number of files is reached,
  # the oldest file is deleted and the rest are shifted from last to first. The
  # default is 7 files.
  number_of_files: 7

  # Permissions to use for file creation. The default is 0600.
  permissions: 0600
```

console

输出到控制面板，测试输出最佳方式。

常规配置
```
# 采集配置
filebeat.inputs:     #收集日志
- type: log         #类型
  enabled: true     #始终收集
  paths:
    - /etc/log/*.log    
# 输出配置
output.console:
  codec.json:
    # 漂亮输出（格式化）
    pretty: true
    #  转义HTML符号
    escape_html: true
```


### Keystore

密钥库地址（一般是包含私钥以及关键数据的文件路径）
```
keystore.path: "${path.config}/beats.keystore"
```

命令
```
创建一个存储密码的keystore：   filebeat keystore create
然后往其中添加键值对，例如：    filebeatk eystore add ES_PWD
使用覆盖原来键的值：           filebeat key store add ES_PWD–force
删除键值对：                  filebeat key store remove ES_PWD
查看已有的键值对：             filebeat key store list
```


### Setup ILM

从7.0版开始，Filebeat在连接到支持生命周期管理的群集时默认使用索引生命周期管理。Filebeat自动加载默认策略并将其应用于Filebeat创建的任何索引。

index lifecycle management (ILM) 索引生命管理，如果它启用了，那么会忽略output.elasticsearch.index 里面的设置。

新特性：当现有索引达到指定的大小或期限时，使用索引生命周期策略自动将过渡到新索引

常规配置
```
setup.ilm.enabled: auto
setup.ilm.rollover_alias: "filebeat"  # 前缀
# filebeat-2020.09.28-000001
setup.ilm.pattern: "{now/d}-000001"   
```

需要了解Date math

详细配置
```
# Configure index lifecycle management (ILM). These settings create a write
# alias and add additional settings to the index template. When ILM is enabled,
# output.elasticsearch.index is ignored, and the write alias is used to set the
# index name.

# Enable ILM support. Valid values are true, false, and auto. When set to auto
# (the default), the Beat uses index lifecycle management when it connects to a
# cluster that supports ILM; otherwise, it creates daily indices.
setup.ilm.enabled: auto

# Set the prefix used in the index lifecycle write alias name. The default alias
# name is 'filebeat-%{[agent.version]}'.
setup.ilm.rollover_alias: "filebeat"

# Set the rollover index pattern. The default is "%{now/d}-000001".
# filebeat-2020.09.28-000001
setup.ilm.pattern: "{now/d}-000001"

# Set the lifecycle policy name. The default policy name is
# 'filebeat'.
setup.ilm.policy_name: "mypolicy"

# The path to a JSON file that contains a lifecycle policy configuration. Used
# to load your own lifecycle policy.
setup.ilm.policy_file:

# Disable the check for an existing lifecycle policy. The default is true. If
# you disable this check, set setup.ilm.overwrite: true so the lifecycle policy
# can be installed.
setup.ilm.check_exists: true

# Overwrite the lifecycle policy at startup. The default is false.
setup.ilm.overwrite: false
```


Logging

配置日志输出的选项。日志记录系统可以将日志写入syslog或轮换日志文件。如果未显式配置日志记录，则使用文件输出，输出路径为/var/log/filebeat。

常规配置
```
#log 输出级别 
logging.level: info 
# 输出方式
logging.to_files: true
# 输出路径、名字、 log文件最大数、文件操作权限
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644
```


详细参数
```
# There are four options for the log output: file, stderr, syslog, eventlog
# The file output is the default.

# Sets log level. The default log level is info.
# Available log levels are: error, warning, info, debug
logging.level: info

# Enable debug output for selected components. To enable all selectors use ["*"]
# Other available selectors are "beat", "publish", "service"
# Multiple selectors can be chained.
# 输出哪些服务的log
logging.selectors: [ ]

# Send all logging output to stderr. The default is false.
logging.to_stderr: false

# Send all logging output to syslog. The default is false.
logging.to_syslog: false

# Send all logging output to Windows Event Logs. The default is false.
logging.to_eventlog: false

# If enabled, Filebeat periodically logs its internal metrics that have changed
# in the last period. For each metric that changed, the delta from the value at
# the beginning of the period is logged. Also, the total values for
# all non-zero internal metrics are logged on shutdown. The default is true.
logging.metrics.enabled: true

# The period after which to log the internal metrics. The default is 30s.
logging.metrics.period: 30s

# Logging to rotating files. Set logging.to_files to false to disable logging to
# files.
logging.to_files: true
logging.files:
  # Configure the path where the logs are written. The default is the logs directory
  # under the home path (the binary location).
  path: /var/log/filebeat

  # The name of the files where the logs are written to.
  name: filebeat

  # Configure log file size limit. If limit is reached, log file will be
  # automatically rotated
  rotateeverybytes: 10485760 # = 10MB

  # Number of rotated log files to keep. Oldest files will be deleted first.
  keepfiles: 7

  # The permissions mask to apply when rotating log files. The default value is 0600.
  # Must be a valid Unix-style file permissions mask expressed in octal notation.
  permissions: 0600

  # Enable log file rotation on time intervals in addition to size-based rotation.
  # Intervals must be at least 1s. Values of 1m, 1h, 24h, 7*24h, 30*24h, and 365*24h
  # are boundary-aligned with minutes, hours, days, weeks, months, and years as
  # reported by the local system clock. All other intervals are calculated from the
  # Unix epoch. Defaults to disabled.
  interval: 0

  # Rotate existing logs on startup rather than appending to the existing
  # file. Defaults to true.
   rotateonstartup: true

# Set to true to log messages in JSON format.
logging.json: false

# Set to true, to log messages with minimal required Elastic Common Schema (ECS)
# information. Recommended to use in combination with `logging.json=true`
# Defaults to false.
logging.ecs: false
```



