---
title: filebeat使用案例
date: 2021-07-05 15:03
categories:
- elk
tags:
- filebeat
- elk
---
	
	
摘要: filebeat 使用案例
<!-- more -->


## 项目有个需求：filebeat(v7.7)采集日志的时间替换为日志时间。通过调研，网上都是通过logstash来转换的
```
filter{
 
  grok{
     // 1 取出时间值 给 一个新字段
     patterns_dir => "./patterns"
     match => { "message" => ["%{IP:source_Ip},%{NUMBER:source_Port},%{IP:dest_Ip},%{NUMBER:dest_Port},%{MYPATTERN:create_Time}"]}
  }
  date {
      // 2 只要时间字段匹配这个格式 就赋值给@timestamp。
     match => [ "create_Time", "yyyy-MM-dd HH:mm:ss:ssssss" ]
     target => "@timestamp"
  }
}
```
filebeat原生支持
全局阅览filebeat官网，终于在processor配置里找到了方法。主要是使用script 、timestamp 这两个属性。
```
script 作用是提取log里的时间值，并赋值给一个字段
timestamp作用是把一个字段值格式化为时间戳。这样采集时间戳就替换成了log里的时间。
```

例如 我的日志长这样
```
2020-08-05 16:21:51.824 [第10行 虚拟]
```

添加下面配置
```
processors:
  ...
  - script:
      lang: javascript
      id: my_filter
      tag: enable
      source: >
        function process(event) {
            var str= event.Get("message");
            var time =str.split(" ").slice(0,2).join(" ");
            event.Put("start_time",time);
        }
 
  - timestamp:
      # 格式化时间值 给 时间戳 
      field: start_time
      # 使用我国东八区时间  解析log时间
      timezone: Asia/Shanghai
      layouts:
        - '2006-01-02 15:04:05'
        - '2006-01-02 15:04:05.999'
      test:
        - '2019-06-22 16:33:51'
```

输出结果为
```
{
  "@timestamp": "2020-08-05T08:21:51.824Z",
  "@metadata": {
    "beat": "filebeat",
    "type": "_doc",
    "version": "7.7.0"
  },
  "message": "2020-08-05 16:21:51.824 [第10行 虚拟]",
  "ecs": {
    "version": "1.5.0"
  }
}
```

附测试时完整配置：
```
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /etc/test/1.log
    reload.enabled: true
    reload.period: 10s
# 这里直接打印出来（测试使用）    
output.console:
  pretty: true
processors:
  - script:
      lang: javascript
      id: my_filter
      tag: enable
      source: >
        function process(event) {
            var str= event.Get("message");
            var time =str.split(" ").slice(0,2).join(" ");
            event.Put("start_time",time);
        }
  - timestamp:
      field: start_time
      timezone: Asia/Shanghai
      layouts:
        - '2006-01-02 15:04:05'
        - '2006-01-02 15:04:05.999'
      test:
        - '2019-06-22 16:33:51'
```

本文中timezone说明
很多朋友问到timezone的问题，我这里详细描述下。

@timestamp 这个字段 系统自带的，默认时间就是采集log的UTC时间 。例如 现在时间是2020-12-30 18:59:58.234 ，那么他的值为2020-12-30T10:59:58.234Z

现在我们手动替换@timestamp为日志时间（东八区），需要将时间字符串解析成UTC时间，赋值给@timestamp，那么我们必须显示的指定timezone 信息。

指定timezone后的表现

log时间字符串：2020-08-05 16:21:51.824
重新赋值的@timestamp值： 2020-08-05T08:17:11.535Z （正确）
未指定timezone后的表现

log时间字符串：2020-08-05 16:21:51.824
重新赋值的@timestamp值： 2020-08-05T16:17:11.535Z （默认使用了UTC零时区解析）



## filebeat收集多日志并自定义索引
filebeat6.x
```
#-------------------------- Elasticsearch output ------------------------------

output.elasticsearch:
  # Array of hosts to connect to.
  hosts: ["192.168.31.234:9200"]
  index: "nginx-%{[beat.version]}-%{+yyyy.MM}"
setup.template.name: "nginx_web"
setup.template.pattern: "nginx_web-"
setup.template.enabled: false$
setup.template.overwrite: true$
```

filebeat7.x
```
output.elasticsearch:
  hosts: ["https://localhost:9200"]
  index: "filebeat-%{[agent.version]}-%{+yyyy.MM.dd}"
setup.template.name: "nginx_web"
setup.template.pattern: "nginx_web-"
setup.template.enabled: false$
setup.template.overwrite: true$
```


## filebeat7.7直接给es传输日志，自定义索引名

ElasticStack从2019年1月29日的6.6.0版本的开始，引入了索引生命周期管理的功能，新版本的Filebeat则默认的配置开启了ILM，导致索引的命名规则被ILM策略控制。
加上这个配置就好了：

filebeat 配置关闭 ILM 即可解决Index Pattern不生效的问题
```
setup.ilm.enabled: false
```

具体配置：
```
#==================== Elasticsearch template setting ==========================
setup.ilm.enabled: false
setup.template.name: "filebeat-127"
setup.template.pattern: "filebeat-127-*"

setup.template.settings:
  index.number_of_shards: 1
  index.number_of_replicas: 0
  index.codec: best_compression 
#-------------------------- Elasticsearch output ------------------------------
output.elasticsearch:
  hosts: ["127.0.0.1:9200"]
  index: "filebeat-127-%{+yyyy.MM.dd}"

  username: "elastic"
  password: "xxxxxxxxxxx"
```  



## filebeat 输出到不同的es index 
```
output.elasticsearch:
  # Array of hosts to connect to.
  hosts: ["10.4.144.173:9200"]
  indices:
    - index: "oom_-java-%{+yyyy.MM.dd}"
      when.contains:
        fields:
          index: 'oom-java'

    - index: "oom-oms-java-%{+yyyy.MM.dd}"
      when.contains:
        fields:
          index: 'oom-oms-java'

  username: "elastic"
  password: "${ES_PWD}"
```