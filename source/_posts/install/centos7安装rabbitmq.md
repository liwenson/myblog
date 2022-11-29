---
title: centos7安装RabbitMQ
date: 2021-07-29 16:00
categories:
- centos7
tags:
- rabbitmq
---
	
	
摘要: Centos7下安装RabbitMQ
<!-- more -->


## erlang 与 rabbitmq对应关系
```
https://www.rabbitmq.com/which-erlang.html
```

## 获取 erlang

```

https://github.com/rabbitmq/erlang-rpm/releases


```


## 获取 rabbitmq

```
https://www.rabbitmq.com/

下载页面
https://www.rabbitmq.com/download.html

https://www.rabbitmq.com/install-rpm.html
```

## 安装
```
yum install erlang-20.3-1.el7.centos.x86_64.rpm -y
yum install rabbitmq-server-3.7.8-1.el7.noarch.rpm -y
```

## 修改配置文件

```
# 目录需要创建
mkdir /usr/local/rabbitmq
cp /usr/share/doc/rabbitmq-server-3.7.8/rabbitmq.config.example /usr/local/rabbitmq/rabbitmq.config
```

修改配置文件,允许远程访问
```
vim rabbitmq.config

%%{loopback_users, []},
修改为

{loopback_users, []}
```


## 启动rabbitmq插件管理
```
rabbitmq-plugins enable rabbitmq_management
```

## 启动RabbitMQ
```
systemctl start rabbitmq-server # 启动rabbitmq服务
systemctl restart rabbitmq-server # 重启服务
systemctl stop rabbitmq-server  # 停止服务
```

## 访问web管理界面
输入你的 ip:15672
进入如下界面
用户名是：guest
密码也是：guest


##  查看服务启动状态
```
rabbitmqctl status
```

## 查询安装默认的用户
```
rabbitmqctl list_users
```

## 配置用户
```
rabbitmqctl add_user ttx ttx2011
rabbitmqctl list_users
rabbitmqctl set_user_tags ttx administrator
rabbitmqctl set_permissions -p "/" ttx ".*" ".*" ".*"
```
