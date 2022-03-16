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


## 确认你的当前git版本

在终端输入：
```
git --version

git version 1.8.3.1
```


## 配置存储库

```
vim /etc/yum.repos.d/wandisco-git.repo

[wandisco-git]
name=Wandisco GIT Repository
baseurl=<http://opensource.wandisco.com/centos/7/git/$basearch/>
enabled=1
gpgcheck=1
gpgkey=<http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco>
```

## 导入存储库GPG密钥

在终端输入：
```
rpm --import <http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco>
```

## 安装Git

```
yum install git
```

## 验证
```
git --version

git version 2.31.1
```
