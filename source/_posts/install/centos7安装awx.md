---
title: centos7安装awx
date: 2021-03-17 15:45
categories:
- centos7
tags:
- awx
---
  
  
摘要: centos7 安装awx
<!-- more -->

## 安装依赖

### 安装docker
```
# curl -sSL https://get.daocloud.io/docker | sh
```

### 安装python3
```
# yum install python3
```

### 安装docker-compose
```
# pip3 install docker-compose   ## 如果没有pip3 使用 yum install python-pip3 安装

## 不要使用下面方式安装
# curl -L https://get.daocloud.io/docker/compose/releases/download/1.28.5/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose
# ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

#### 安装ansible
```
# yum install epel-release
# yum install ansible
```

## 部署awx

从18.0版开始，AWX Operator是安装AWX的首选方法。


### 下载 awx
```
# cd /opt
# git clone https://github.com/ansible/awx.git  网络不好试试  https://github.com.cnpmjs.org/ansible/awx.git
# cd awx/installer/
```

修改配置 `inventory` 文件配置
```
pg_password=***
rabbitmq_password=***
admin_password=***
project_data_dir=/var/lib/awx/projects
```

### 部署安装
```
# ansible-playbook -i inventory install.yml
```

### 等待Docker容器启动
```
# docker ps -a
```


部署完成，浏览器访问`本机IP地址`，默认使用`80`端口
