---
title: centos7安装nexus仓库
date: 2023-03-07 09:45
categories:
- centos7
tags:
- nexus
---
  
  
摘要: desc
<!-- more -->

## Nexus是什么？

Nexus 是一个强大的maven仓库管理器，它极大地简化了本地内部仓库的维护和外部仓库的访问。

不仅如此，他还可以用来创建yum、pypi、npm、docker、nuget、rubygems 等各种私有仓库。

如果使用了公共的 Maven 仓库服务器，可以从 Maven 中央仓库下载所需要的构件（Artifact），但这通常不是一个好的做法。 正常做法是在本地架设一个 Maven 仓库服务器，即利用 Nexus 私服可以只在一个地方就能够完全控制访问和部署在你所维护仓库中的每个 Artifact。 Nexus 在代理远程仓库的同时维护本地仓库，以降低中央仓库的负荷, 节省外网带宽和时间，Nexus 私服就可以满足这样的需要。 Nexus 是一套 "开箱即用" 的系统不需要数据库，它使用文件系统加 Lucene 来组织数据。 Nexus 使用 ExtJS 来开发界面，利用 Restlet 来提供完整的 REST APIs，通过 m2eclipse 与 Eclipse 集成使用。 Nexus 支持 WebDAV 与 LDAP 安全身份认证。 Nexus 还提供了强大的仓库管理功能，构件搜索功能，它基于 REST，友好的 UI 是一个 extjs 的 REST 客户端，它占用较少的内存，基于简单文件系统而非数据库。

在本地构建 nexus私服的好处有：

        加速构建
        节省带宽
        节省中央 maven 仓库的带宽
        稳定（应付一旦中央服务器出问题的情况）
        控制和审计
        能够部署第三方构件
        可以建立本地内部仓库
        可以建立公共仓库

## 下载

官网地址：<https://www.sonatype.com/>

    可以直接通过下边链接下载最新版本：https://www.sonatype.com/oss-thank-you-tar.gz
    可以通过后边的这个链接选择历史版本：https://help.sonatype.com/repomanager3/download/download-archives—repository-manager-3

## 安装jdk-1.8

nexus的安装依赖jdk环境。最好安装1.8版本的，否则可能会遇到其他不可知问题。

## 部署nexus

解压

```bash
[root@nexus /opt/nexus]$tar xf nexus-3.49.0-02-unix.tar.gz
[root@nexus /opt/nexus]$ls
nexus-3.49.0-02  nexus-3.49.0-02-unix.tar.gz  sonatype-work
```

下载到指定目录并解压，我们可以看到解压后有通常两个文件。
|||
|---|---|
|nexus-x.x.x  |Nexus运行所需要的文件，如运行脚本，依赖jar包等|
|sonatype-work  |该目录包含Nexus生成的配置文件、日志文件、仓库文件等|

## 启动

```bash
cd /opt/nexus/nexus-3.49.0-02/bin
./nexus run &
```

## 访问

默认监听端口为 8081，默认用户名密码为 admin/admin123 ，因此可以访问以下首页并登陆。

## 优化配置

### 配置运行用户

这个地方可以使用root运行，不过官方文档里边也不建议使用root来运行，因此使用普通用户来运行。

```bash
[root@nexus ~] useradd --system --no-create-home nexus
[root@nexus bin]$vim nexus-3.49.0-02/bin/nexus.rc

run_as_user="nexus"

配置之后记得更改目录权限，否则下次启动会没有权限。

[root@nexus /opt/nexus/] chown -R nexus.nexus /opt/nexus/
```

### system

```bash
vi /etc/systemd/system/nexus.service

[Unit]
Description=Nexus Service
After=syslog.target network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/nexus-3.49.0-02/bin/nexus start
ExecStop=/opt/nexus/nexus-3.49.0-02/bin/nexus stop
User=nexus
Group=nexus
Restart=on-failure

[Install]
WantedBy=multi-user.target


systemctl daemon-reload
systemctl enable nexus.service
systemctl start nexus.service
```

### jvm参数修改

```bash
vi /opt/nexus/nexus-3.49.0-02/bin/nexus.vmoptions
这里报错默认，不做修
改
-Xms2703m
-Xmx2703m
-XX:MaxDirectMemorySize=2703m
-XX:+UnlockDiagnosticVMOptions
-XX:+LogVMOutput
-XX:LogFile=../nexusdata/nexus3/log/jvm.log
-XX:-OmitStackTraceInFastThrow
-Djava.net.preferIPv4Stack=true
-Dkaraf.home=.
-Dkaraf.base=.
-Dkaraf.etc=etc/karaf
-Djava.util.logging.config.file=etc/karaf/java.util.logging.properties
-Dkaraf.data=../nexusdata/nexus3
-Dkaraf.log=../nexusdata/nexus3/log
-Djava.io.tmpdir=../nexusdata/nexus3/tmp
-Dkaraf.startLocalConsole=false
```

### 修改端口

一般使用默认的，如果需要修改，则更改 /opt/nexus/nexus-3.49.0-02/etc/nexus-default.properties里边的配置。

这里不做修改了

### 配置存储及日志位置

```bash
[root@nexus bin]$vim /opt/nexus/nexus-3.49.0-02/bin/nexus.vmoptions

一般都不做修改，使用默认即可，这里列出是为了了解这个点。

-XX:LogFile=../sonatype-work/nexus3/log/jvm.log
-Dkaraf.data=../sonatype-work/nexus3
-Djava.io.tmpdir=../sonatype-work/nexus3/tmp

```

### 修改系统文件句柄

安装完成之后，注意页面左上角会有一个告警，这个告警的意思是系统默认的最大文件句柄太小了。

```bash
echo "nexus  -  nofile 65536" >> /etc/security/limits.conf
```

## 错误处理

### 1
```
2023-03-07 11:02:04,352+0800 WARN  [Timer-0]  *SYSTEM java.util.prefs - Couldn't flush user prefs: java.util.prefs.BackingStoreException: Couldn't get file lock.
2023-03-07 11:02:34,350+0800 WARN  [Timer-0]  *SYSTEM java.util.prefs - Could not lock User prefs.  Unix error code 2.
```

添加 -Djava.util.prefs.userRoot=/nexus-data/javaprefs 应该可以解决问题，假设 nexus 数据目录位于 /nexus-data/

```
vi /opt/nexus/nexus-3.49.0-02/bin/nexus.vmoptions

...

```

从3.38.1升级到3.42.0后也出现了同样的问题。经过一番调查后发现，java.util.prefs.userRoot属性确实在这两个版本之间的某个地方丢失了。普通Nexus 3.38.1中的默认值是/ Nexus -data/javaprefs。

### 2

```
2023-03-07 11:09:42,798+0800 WARN  [qtp183869950-618]  *UNKNOWN com.sonatype.nexus.plugins.outreach.internal.outreach.SonatypeOutreach - Could not download page bundle
org.apache.http.conn.ConnectTimeoutException: Connect to sonatype-download.global.ssl.fastly.net:443 [sonatype-download.global.ssl.fastly.net/185.45.6.103] failed: connect timed out

```

处理

Capabilities Outreach:Management 连接超时，关闭服务即可
[Server administration and configuration] → [System] → [Capabilities] → [Disable]
