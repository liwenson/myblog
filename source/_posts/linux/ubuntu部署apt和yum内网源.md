---
title: ubuntu 部署apt和yum 内网镜像源
date: 2022-09-23 13:41
categories:
- ubuntu
tags:
- apt
- yum
---
  
  
摘要: 使用Ubuntu20.04 部署apt和yum 内网镜像源
<!-- more -->

## 修改镜像源为阿里云源

编辑如下文件

```bash
mv /etc/apt/sources.list /etc/apt/sources.list.back
vim /etc/apt/sources.list
```

阿里云镜像源

```txt
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
```

编辑文件完成后，执行如下命令进行更新缓存

```bash
sudo apt update 
sudo apt upgrade
```


## 安装同步工具

```bash
sudo apt-get install apt-mirror reposync createrepo
```

