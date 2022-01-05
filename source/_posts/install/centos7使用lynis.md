---
title: centos7使用lynis
date: 2021-12-13 16:29
categories:
- linux
tags:
- lynis
---
  
  
摘要: centos7使用lynis
<!-- more -->

## 前言
### lynis简介

Lynis是一款Unix系统的安全审计以及加固工具，能够进行深层次的安全扫描，其目的是检测潜在的时间并对未来的系统加固提供建议。这款软件会扫描一般系统信息，脆弱软件包以及潜在的错误配置。扫描完成后，Lynis还会为我们生成一份包含所有扫描结果的安全报告。
[Get Started with Lynis - Installation Guide - CISOfy](https://cisofy.com/documentation/lynis/get-started/#first-run)


### Lynis受众与用例

1） Lynis的典型用例包括：

    安全审核
    一致性测试（例如，PCI，HIPAA，SOx）
    渗透测试
    漏洞检测
    系统强化

2） 受众和用例

    开发人员：测试该Docker映像，或改善已部署Web应用程序的强化。
    系统管理员：运行日常运行状况扫描，以发现新的漏洞。
    IT审核员：向同事或客户展示可以采取哪些措施来提高安全性。
    渗透测试人员：发现客户端系统上的安全漏洞，最终可能导致系统受损。
    支持的操作系统

### 支持的系统

Lynis几乎可以在所有基于UNIX的系统和版本上运行，包括:

    1） AIX
    2） FreeBSD
    3） HP-UX
    4） Linux
    5） macOS
    6） NetBSD
    7） NixOS
    8） OpenBSD
    9） Solaris
    10） and others
同样也可以在Raspberry Pi，IoT设备和QNAP存储设备等系统上运行。

### Audit步骤

使用Lynis进行的典型扫描过程：
    1） 初始化
    2） 执行基本检查，例如文件所有权
    3） 确定操作系统和工具
    4） 搜索可用的软件组件
    5） 检查最新的Lynis版本
    6） 运行启用的插件
    7） 按类别运行安全测试
    8） 执行您的自定义测试（可选）
    9） 报告安全扫描状态

除了屏幕上显示的报告和信息外，有关扫描的所有技术细节都存储在日志文件（lynis.log）中。警告和建议之类的结果存储在单独的报告文件（lynis-report.dat）中。

Lynis执行数百项单独的测试。大多数测试是用Shell脚本编写的，并且具有唯一的标识符（例如KRNL-6000）。使用唯一标识符，可以调整安全扫描。


## [官方](https://cisofy.com/lynis/)


## 安装

方式一
[下载压缩包](https://cisofy.com/downloads/lynis/)
```
mkdir -p /usr/local/lynis
cd /usr/local/lynis
```
从 Lynis 下载页面，将链接复制到 Lynis tarball（以 lynis-<version>.tar.gz 结尾）。

将此链接与 一起使用 wget （通常默认安装） 。 macOS 用户可以使用 curl 工具，BSD 用户可以使用 fetch 。 
```
curl https://cisofy.com/files/lynis-<version>.tar.gz -o lynis.tar.gz

tar xfvz lynis-<version>.tar.gz
```


方式二
**Git**
```
git clone https://github.com/CISOfy/lynis
```

方式三

Red Hat
```
yum install lynis
```

Debian
```
apt-get install lynis
```

openSUSE
```
zypper install lynis
```

macOS
```
brew install lynis
```

## 使用

#### 常用的选项

|参数	| 说明|
| --- | --- |
|--auditor	|审计人员           |
|--checkall,-c	|开始审查整个系统            |
|--check-update	|检查lynis是否需要升级   |
|--cronjob	|作为定时任务启动 (includes -c -Q)   |
|--help,-h	|显示帮助        |
|--manpage	|查看手册页    |
|--nocolors	|不使用任何颜色   |
|--pentest	|执行渗透测试扫描(非特权)   |
|--quick,-Q	|除错误外，不要等待用户输入   |
|--quiet	|仅显示警告(包括 -quick，但不等待)   |
|--reverse-colors|	为浅色背景使用不同的配色方案    |
|--wait | 等待用户按回车键显示下一节的报告  |
|--version,-V	|检查版本   |


#### 要查看 Lynis 中所有可用的命令：
```
./lynis show commands
```


#### 显示其状态以及如何启动的建议
```
cd lynis

./lynis
```

#### 运行系统审查
```
./lynis audit system
```

#### 查看扫描类别
```
lynis show groups
```

#### 指定类别扫描
```
./lynis --tests-from-group "group name"
```

```
./lynis --tests-from-group "php ssh"
```

#### 审查恶意软件
```
lynis --tests-from-group "hardening malware" 需要安装malware scanner才能完成这个功能

```
[Lynis control HRDN-7230: Presence malware scanner - CISOfy](https://cisofy.com/lynis/controls/HRDN-7230/)


#### 查看扫描详情

在每项suggestion和warning后有test_id

通过 `lynis show tests` 查看所有test_id

**查看详细**
```
./lynis show details PHP-237
```

#### 审计模块明细表
```
./lynis show tests
```

#### 查看日志与数据文件

默认路径
```
  Files:
  - Test and debug information      : /var/log/lynis.log
  - Report data                     : /var/log/lynis-report.dat
```

检查告内容:
```
grep Warning /var/log/lynis.log
more /var/log/lynis.log|grep Warning
more /var/log/lynis.log|grep Suggestion
```

检查建议内容:
```
grep Suggestion /var/log/lynis.log
```

#### 检查更新
```
./lynis update info
```

#### Lynis 使用颜色编码使报告更容易解读。

    绿色。一切正常
    黄色。跳过、未找到，可能有个建议
    红色。你可能需要仔细看看这个



## 配置
默认lynis自带一个名为 default.prf 的默认配置文件
```
/etc/lynis/default.prf


git 方式安装的在lynis 目录下面
```


无需直接修改这个默认的配置文件，只需要新增一个 `custom.prf`  文件将自定义的信息加入其中就可以了。

如果要确认使用了什么配置文件，请使用 “show profile” 命令
```
./lynis show profiles
```


查看设置。可以选择添加–brief 和 –nocolors 仅显示设置。
```
./lynis show settings
```

#### 自定义配置文件
```
touch custom.prf
```
然后将首选选项复制到您的自定义配置文件

#### 从命令行配置设置
```
./lynis configure settings debug=yes
```

要更改多个设置，请使用冒号将它们分开。
```
./lynis configure settings debug=yes:quick=yes
```

确认是否使用 show settings 命令获取了新设置。

```
./lynis show settings
```

## 插件

#### 目的

Lynis 用 Shell 脚本编写，Shell 脚本是一种通用脚本语言，可在运行 Linux 或基于 UNIX 的所有系统上使用。因此，大多数系统管理员可以轻松地为 Lynis 创建自己的测试。当您要编写自己的测试或插件时，这很有用。在本文档中，我们介绍了如何创建一个包含一些自定义测试的插件。

Lynis 中的插件具有收集（更多）数据的主要功能。然后，任何预定义或自定义测试都可以使用此数据。另一个选择是，数据仅存储在报告文件中，并由第三方工具进行分析。
插件执行步骤

Lynis 每次都会执行完整的步骤周期。对于插件，有两个时刻可以运行，我们称为阶段 1 和阶段 2。完整的周期如下所示：

    初始化
    操作系统检测
    检测二进制
    插件阶段 1
    运行内置测试
    运行任何自定义测试（可选）
    插件阶段 2
    显示报告
    停止程序

#### 插件位置

第一步是了解 Lynis 的安装位置，尤其是插件存储在哪个目录中。
```
lynis show plugindir
```
注意：运行 Lynis 时，该路径也会显示在屏幕上，并存储在您的日志文件（通常为 /var/log/lynis.log）中。


#### 官方插件库
[Lynis plugins - CISOfy](https://cisofy.com/lynis/plugins/)


#### 自定义插件

[官方开发文档](https://cisofy.com/documentation/lynis/plugins/development/)




## 自动化对系统审核
```
vim /etc/systemd/system/lynis.service


############################################################
#
# Lynis service file for systemd
#
############################################################
# Do not remove, so Lynis can provide a hint when a newer unit is available
# Generator=lynis
# Version=1
############################################################

[Unit]
Description=Security audit and vulnerability scanner
Documentation=https://cisofy.com/docs/

[Service]
Nice=19
IOSchedulingClass=best-effort
IOSchedulingPriority=7
Type=simple
ExecStart=/usr/bin/lynis audit system --cronjob

[Install]
WantedBy=multi-user.target

```

Create timer unit (/etc/systemd/system/lynis.timer
```
############################################################
#
# Lynis timer file for systemd
#
############################################################
# Do not remove, so Lynis can provide a hint when a newer unit is available
# Generator=lynis
# Version=1
############################################################

[Unit]
Description=Daily timer for the Lynis security audit and vulnerability scanner

[Timer]
OnCalendar=daily
RandomizedDelaySec=1800
Persistent=false

[Install]
WantedBy=timers.target

############################################################
```

```
systemctl daemon-reload
```
```
systemctl enable --now lynis.timer
```

自定义
```
systemctl edit lynis.timer


[Timer]
OnCalendar=
OnCalendar=*-*-* (or) 03:00:00

```

