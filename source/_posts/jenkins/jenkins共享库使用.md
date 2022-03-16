---
title: jenkins共享库使用
date: 2021-08-11 11:32
categories:
- jenkins
tags:
- jenkins
---
	
	
摘要: desc
<!-- more -->


## 安装docker
在构建代码是会使用jenkins触发docker启用一个jenkins slave 来构建代码

安装略

## 安装jenkins

jenkins [rpm下载地址](https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat-stable/)

```
yum install jenkins-2.289.3-1.1.noarch.rpm -y
```


默认安装路径

自动安装完成之后： 
```
/etc/rc.d/init.d/jenkins  启动脚本

/usr/lib/jenkins/jenkins.war    WAR包 

/etc/sysconfig/jenkins       配置文件

/var/lib/jenkins/        默认的JENKINS_HOME目录

/var/log/jenkins/jenkins.log    Jenkins日志文件

```

### 错误
```
/usr/bin/java: No such file or directory
```
在 /etc/rc.d/init.d/jenkins 中配置java路径


### 安装jenkins插件

|插件|作用||
|---|---|---|
|http Request |发起http请求|
|build user vars | 获取用户名称 |
|DingTalk | 钉钉消息|
|ansiColor |输出彩色信息 |


## 配置jenkins


## 编写 jenkins SharedLibraries

