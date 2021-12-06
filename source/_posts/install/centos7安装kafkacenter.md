---
title: centos7 快速启动kafkacenter
date: 2021-07-24 17:20
categories:
- centos7
tags:
- kafka
- kafkacenter
---
	
	
摘要: center7 快速启动kafkacenter
<!-- more -->

### 以官方文档为主

### 目录创建
```
mkdir -p /opt/kafkaCenter/{elasticsearch/{data,config,plugins},kafkaCenter/config,mysql/{db,logs}}
```

es配置文件放在 /opt/kafkaCenter/elasticsearch/config/elasticsearch.yml
KafkaCenter 配置文件放在 /opt/kafkaCenter/kafkaCenter/config/application.properties

### es配置文件 
```
elasticsearch.yml

#集群名
cluster.name: "elasticsearch"
# 允许外部网络访问
network.host: 0.0.0.0
#支持跨域
http.cors.enabled: true
#支持所有域名
http.cors.allow-origin: "*"
# 关闭xpack安全校验，在kibana中使用就不需要输入账号密码
xpack.security.enabled: false
```


### 创建 docker.compose.yml
```
vim /opt/kafkaCenter/docker-compose.yml


version: '2'
services: 
  mysql:
    restart: always
    image: mysql:5.7.16
    container_name: mysql-server
    volumes:
      - /opt/kafkaCenter/mysql/db:/var/lib/mysql
      - /opt/kafkaCenter/mysql/logs:/var/log/mysql
    ports:
      - 3306:3306
    environment:
      - MYSQL_ROOT_PASSWORD=abc123456

  elasticsearch:
    container_name: elasticsearch
    image: elasticsearch:7.10.1
    ports:
      - "9200:9200"
    volumes:
      - /opt/kafkaCenter/elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
      - /opt/kafkaCenter/elasticsearch/data:/usr/share/elasticsearch/data
      - /opt/kafkaCenter/elasticsearch/plugins:/usr/share/elasticsearch/plugins
    environment:
      - discovery.type=single-node
      - http.port=9200
      - http.cors.enabled=true
      - http.cors.allow-origin=*
      - http.cors.allow-headers=X-Requested-With,X-Auth-Token,Content-Type,Content-Length,Authorization
      - http.cors.allow-credentials=false
      - bootstrap.memory_lock=true
      - 'ES_JAVA_OPTS=-Xms512m -Xmx2048m'
      - "COMPOSE_PROJECT_NAME=elasticsearch-server"
    restart: always

  kafkaCenter:
    restart: always
    image: xaecbd/kafka-center:2.3.0
    container_name: kafka-center
    volumes:
      - /opt/kafkaCenter/kafkaCenter/config/application.properties:/opt/app/kafka-center/config/application.properties
    ports:
      - 8080:8080
      - 8000:8000
    depends_on:
      - mysql
      - elasticsearch

```

### 启动 
```
docker-compose up -d
```

mysql 导入表结构

官方脚本地址，官方sql脚本中部分 sql 语句缺少 ; 结束，需要自己补全，不然脚本会运行错误
```
https://xaecbd.github.io/KafkaCenter/KafkaCenter-Core/sql/table_script.sql
```

配置文件导入
官方 应用配置
```
https://xaecbd.github.io/KafkaCenter/KafkaCenter-Core/src/main/resources/application.properties
```
修改应用配置中的 mysql 信息，如果，localhost找不到，修改为ip:port



### 错误处理

elasticsearch启动报错

```
ElasticsearchException[failed to bind service]; nested: AccessDeniedException[/usr/share/elasticsearch/data/nodes];
Likely root cause: java.nio.file.AccessDeniedException: /usr/share/elasticsearch/data/nodes
```

data 目录授权
```
chmod 777 /opt/kafkaCenter/elasticsearch/data
```


### 重启 
```
docker-compose down 
docker-compose up -d
```


### 未解决的报错

暂时不影响使用
```
2021-07-24 09:36:01,325 ERROR [pool-2-thread-3] AlertaService: get virtual-email-groups has error.
java.lang.IllegalArgumentException: URI is not absolute
	at java.net.URI.toURL(URI.java:1088)
	at org.springframework.http.client.SimpleClientHttpRequestFactory.createRequest(SimpleClientHttpRequestFactory.java:145)
	at org.springframework.http.client.support.HttpAccessor.createRequest(HttpAccessor.java:124)
	at org.springframework.web.client.RestTemplate.doExecute(RestTemplate.java:735)
	at org.springframework.web.client.RestTemplate.execute(RestTemplate.java:674)
	at org.springframework.web.client.RestTemplate.getForObject(RestTemplate.java:315)
	at org.nesc.ec.bigdata.service.AlertaService.getAlarmGroupMap(AlertaService.java:75)
	at org.nesc.ec.bigdata.job.CollectConsumerLagJob.watchAlert(CollectConsumerLagJob.java:121)
	at org.nesc.ec.bigdata.job.CollectConsumerLagJob.collectConsumerLag(CollectConsumerLagJob.java:83)
	at org.nesc.ec.bigdata.job.InitRunJob.lambda$runCollectConsumerLagJob$0(InitRunJob.java:69)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.runAndReset(FutureTask.java:308)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.access$301(ScheduledThreadPoolExecutor.java:180)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:294)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
```
