---
title: centos7部署skywalking
date: 2022-12-30 10:30
categories:
- skywalking
tags:
- APM
- skywalking
- sky
---
  
  
摘要: centos7 部署 skywalking
<!-- more -->

## 部署

略

```bash
# 新建用户
useradd -s /sbin/nologin skywalking;\
mkdir /home/skywalking/data
```

## systemctl

原有脚本行首有注释导致systemd启动报错

```bash
Starting skywalking-oap...
Failed at step EXEC spawning /opt/skywalking/bin/oapService.sh: Exec format error
skywalking-oap.service: control process exited, code=exited status=203
Failed to start skywalking-oap.
Unit skywalking-oap.service entered failed state.
skywalking-oap.service failed.
skywalking-oap.service holdoff time over, scheduling restart.
Stopped skywalking-oap.
```

去除行首注释

```bash
sed -i -c -e '/^#/d' /opt/skywalking/bin/oapService.sh;\
sed '1 i#!/usr/bin/env sh' -i /opt/skywalking/bin/oapService.sh
```

```bash
vim /usr/lib/systemd/system/skywalking.service


[Unit]
Description=skywalking service
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
Environment=JAVA_HOME=/data/java/jdk
ExecStart=/data/skywalking/bin/startup.sh
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=process
PrivateTmp=true
StandardOutput=syslog
StandardError=inherit

[Install]
WantedBy=multi-user.target

```

也可以拆分，单独启动server 和ui 程序

```bash
vim /usr/lib/systemd/system/skywalking-oap.service


[Unit]
Description=skywalking-oap
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
Environment=JAVA_HOME=/data/java/jdk
ExecStart=/data/skywalking/bin/oapService.sh
Restart=always
PrivateTmp=true
LimitNOFILE=65536
WorkingDirectory=/data/skywalking/bin
[Install]
WantedBy=multi-user.target

```

```bash
vim  /usr/lib/systemd/system/skywalking-webapp.service

[Unit]
Description=skywalking-webapp
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
Environment=JAVA_HOME=/data/java/jdk
ExecStart=/data/skywalking/bin/webappService.sh
Restart=always
PrivateTmp=true
LimitNOFILE=65536
WorkingDirectory=/data/skywalking/bin
[Install]
WantedBy=multi-user.target
```

命令

```bash
#重载配置
systemctl daemon-reload

#开机自启
systemctl enable skywalking

#重启skywalking
systemctl restart skywalking

systemctl status skywalking

## 或者重启skywalking

systemctl restart skywalking-oap
systemctl restart skywalking-webapp

systemctl status skywalking

```

## skywalking 使用

skywalking-oap-server服务启动后会暴露 11800 和 12800 两个端口，分别为收集监控数据的端口11800和接受前端请求的端口12800

可以将脚本放在容器中，或者直接在虚拟机中用来启动java进程

```bash
#!/bin/sh

export SW_AGENT_NAME={appname}
export SW_AGENT_INSTANCE=`hostname`
export SW_AGENT_COLLECTOR_BACKEND_SERVICES=1.2.3.4:11800
export SW_AGENT_SPAN_LIMIT=2000
export JAVA_AGENT=-javaagent:/ztocwst/service/{appname}/skywalking/skywalking-agent.jar

cd {appdir}/{appname}
nohup java -jar $JAVA_AGENT -Xdebug -Xnoagent {jvm} -Duser.timezone=GMT+08 -Dfile.encoding=UTF-8 -XX:NewRatio=1 -XX:SurvivorRatio=8 {appdir}/{appname}/bin/app.jar
```

通过发布工具，动态替换脚本中的变量
