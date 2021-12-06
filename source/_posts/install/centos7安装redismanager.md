---
title: centos7安装redismanager
date: 2021-07-28 15:08
categories:
- centos7
tags:
- redis
---
	
	
摘要: centos7安装redismanager
<!-- more -->


## 创建目录
```
mkdir -p /opt/redismanager/{mysql/{db,logs},redismanager}
```


## docker-compose.yml
```
vim /opt/redismanager/docker-compose.yml


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

  redis-manager:
    restart: always
    image: reasonduan/redis-manager
    container_name: redis-manager
		environment:
		  - DATASOURCE_DATABASE='redis_manager'
			- DATASOURCE_URL='jdbc:mysql://127.0.0.1:3306/redis_manager?useUnicode=true&characterEncoding=utf-8&serverTimezone=GMT%2b8'
			- DATASOURCE_USERNAME='root'
			- DATASOURCE_PASSWORD='abc123456'
    ports:
      - 8182:8182
    depends_on:
      - mysql

```

## 数据库创建
```
CREATE DATABASE `redis_manager` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
```

## 重启
```
```