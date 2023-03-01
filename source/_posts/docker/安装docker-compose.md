---
title: 安装docker-compose
date: 2023-02-22 09:51
categories:
- docker
tags:
- docker-compose
---
  
  
摘要: desc
<!-- more -->

## 从github上下载docker-compose二进制文件安装

github

```bash
sudo curl -L https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
```

若是github访问太慢，可以用daocloud下载

```bash
sudo curl -L https://get.daocloud.io/docker/compose/releases/download/v2.16.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
```

添加可执行权限

```bash
sudo chmod +x /usr/local/bin/docker-compose
```

## docker

```bash
curl -o /etc/yum.repos.d/docker-ce.repo  http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```
