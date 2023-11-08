---
title: maven配置mirror与repository的优先级
date: 2023-06-20 11:20
categories:
- maven
tags:
- mvn
---
  
  
摘要: mirror 与repository 以及它们之间的配置优先级
<!-- more -->

### 为什么需要多配置一个maven公共仓库而不是仅仅一个maven私服即可？

如果仅配置一个Maven私服，一般情况下是没有问题的。但是可能并不好用，比如maven私服没有的jar包，就会读取Maven公共仓库下载。因为这个Maven公共仓库是国外的地址，可能会非常慢，甚至下载不来对应的jar。因此就需要额外多配置一个公共的Maven仓库，比如阿里云的Maven库

### 谨慎配置 mirrorOf 为 *

```
<mirrors>
  <mirror>
    <id>nexus-aliyun-public</id>
    <mirrorOf>*</mirrorOf> 
    <name>Nexus aliyun</name> 
    <url>https://maven.aliyun.com/nexus/content/groups/public</url>
  </mirror>
  <mirror>     
    <id>nexus-snapshots</id>     
    <mirrorOf>snapshots</mirrorOf>     
    <url>http://47.112.201.193:8081/nexus/content/repositories/snapshots</url>     
  </mirror>
</mirrors>
```

maven 读取 mirror 配置是从上往下读取的，如果 mirrorOf 配置为 * 并且在第一个。说明了所有的远程 jar 都是通过 nexus-aliyun-public 这个 mirror 去下载。忽略 nexus-snapshots 这个镜像配置。如果 nexus-snapshots 是私服的话，那么公司的私服jar 就会下载不下来了。

### mirrorOf与repositoryId相同的时候优先是使用mirror的地址


- mirrorOf等于*的时候覆盖所有repository配置
- 存在多个mirror配置的时候mirrorOf等于*放到最后
- 只配置mirrorOf为central的时候可以不用配置repository


settings.xml一般这样设置

```
<?xml version="1.0" encoding="UTF-8"?>
<settings
    xmlns="http://maven.apache.org/SETTINGS/1.0.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
    <localRepository>X:\工具\maven资源\repository</localRepository>
    <pluginGroups></pluginGroups>
    <proxies></proxies>
    <servers></servers>
    <mirrors>
        <mirror>
            <id>nexus-aliyun</id>
            <name>Nexus aliyun</name>
            <mirrorOf>central</mirrorOf>
            <url>http://maven.aliyun.com/nexus/content/groups/public</url>
        </mirror>
        <mirror>
            <id>nexus-mine</id>
            <name>Nexus mine</name>
            <mirrorOf>*</mirrorOf>
            <url>http://xx.xx.xx.xx/nexus/content/groups/public</url>
        </mirror>
    </mirrors>
    <profiles></profiles>
</settings>
```

nexus-aliyun使用阿里云的镜像作为central中央仓库

nexus-mine作为私服，mirrorOf配置为*来提供中央仓库中不存在的jar包

### mirror 与 repository 配置优先级

mirror 优先级 高于 repository 配置。 特别是 mirror 配置了 mirrorOf等于 * ， 那么 repository 配置就失效了


### maven获取真正起作用的repository集合流程

首先会获取pom.xml里的repository集合，然后在settings.xml里找mirrors元素， 如果repository的id和mirror的mirrorOf的值相同，则该mirror替代该repository， 如果该repository找不到对应的mirror， 则使用其本身，依此可以得到最终起作用的repository集合， repositories中默认包含了中央仓库central，当然也可以重新它的url； 可以理解mirror是复写了对应id的repository







