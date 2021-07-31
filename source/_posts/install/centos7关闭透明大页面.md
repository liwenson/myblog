---
title: CentOS7关闭透明大页面
date: 2021-07-29 15:42
categories:
- linux
tags:
- linux
---
	
	
摘要: desc
<!-- more -->

## 开机自动关闭服务化

这里提供另一个将脚本注入到启动服务的方法，新建一个服务配置：
```
vi /etc/systemd/system/disable-thp.service
```

```
[Unit]
Description=Disable Transparent Huge Pages (THP)

[Service]
Type=simple
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
```

reload，配置开机自启动：
```
systemctl daemon-reload
systemctl start disable-thp
systemctl enable disable-thp
```
重启后进行验证：
```
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/defrag
```