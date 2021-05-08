---
title: centos7自动安装更新
date: 2021-05-06 09:30
categories:
- centos7
tags:
- yum
---
  
  
摘要: centos7安装更新
<!-- more -->

## 配置yum 源

备份本地源
```
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo_bak
```
获取阿里源配置文件
```
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
```
更新epel仓库
```
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
```
更新cache
```
yum makecache
```

## 更新
```
yum update -y   # yum -y update (会更新软件、内核、系统版本), 更新系统内核、需要重启系统才会生效
```

## 自动安装安全更新
```
yum install yum-cron -y
```
配置 yum-cron
vim  /etc/yum/yum-cron.conf
```
update_cmd = security
update_messages = yes
download_updates = yes 
apply_updates = yes
```

## 启动
执行命令"systemctl start yum-cron" 启动yum-cron
```
systemctl start yum-cron
```
开机自动启动
```
systemctl enable yum-cron
```
