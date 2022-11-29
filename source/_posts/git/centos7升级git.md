#---
title: centos7 升级git版本
date: 2022-03-16 13:45
categories:
- centos7
tags:
- git
---
  
  
摘要: desc
<!-- more -->


## 方案一
### 安装ius源
```
yum install \
https://repo.ius.io/ius-release-el7.rpm \
https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
```

页面查看ius源最新的git版本
https://repo.ius.io/7/x86_64/packages/g/

### 删除老版本，并安装新版本git
```
yum remove git
yum install git236
git --version
```


## 方案二

### 确认你的当前git版本

在终端输入：
```
git --version

git version 1.8.3.1
```


### 配置存储库

```
vim /etc/yum.repos.d/wandisco-git.repo

[wandisco-git]
name=Wandisco GIT Repository
baseurl=<http://opensource.wandisco.com/centos/7/git/$basearch/>
enabled=1
gpgcheck=1
gpgkey=<http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco>
```

### 导入存储库GPG密钥

在终端输入：
```
rpm --import <http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco>
```

### 安装Git

```
yum install git
```

### 验证
```
git --version

git version 2.31.1
```
