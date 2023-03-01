---
title: centos7安装auditd
date: 2023-02-01 10:27
categories:
- centops7
tags:
- auditd
---
  
  
摘要: centos7安装auditd
<!-- more -->

## 审计介绍

Linux 审计系统提供了一种跟踪系统上与安全相关的信息的方法。根据预先配置的规则，Audit 会生成日志条目，以尽可能多地记录有关系统上发生的事件的信息。此信息对于关键任务环境确定安全策略的违反者及其执行的操作至关重要。审计不会为您的系统提供额外的安全性；相反，它可用于发现违反您系统上使用的安全策略的情况。可以通过其他安全措施（例如 SELinux）进一步防止这些违规行为。

audit能够在日志中记录的信息有:

    时间的日期时间、类型和结果
    主体和客体的敏感度标签
    事件与触发事件的用户身份的关联
    对审计配置的所有修改和访问审计日志文件的尝试
    身份验证机制的所有用途，例如 SSH、Kerberos 等
    对任何受信任数据库的更改，例如​​/etc/passwd​​
    尝试将信息导入或导出系统
    根据用户身份、主题和对象标签以及其他属性包括或排除事件

使用审计系统也是许多与安全相关的认证的要求。审核旨在满足或超过以下认证或合规指南的要求：

    受控访问保护配置文件 (CAPP)
    标记安全保护配置文件 (LSPP)
    规则集基础访问控制 (RSBAC)
    国家工业安全计划操作手册 (NISPOM)
    联邦信息安全管理法案 (FISMA)
    支付卡行业 — 数据安全标准 (PCI-DSS)
    安全技术实施指南 (STIG)

## 审计能做什么

**跟踪文件访问:** 审计可以跟踪文件或目录是否已被访问、修改、执行，或者文件的属性是否已更改。这很有用，例如，检测对重要文件的访问并在这些文件之一损坏的情况下提供审计跟踪。

**监控系统调用:** 可以将审计配置为每次使用特定系统调用时生成日志条目。这可以用来，例如，通过监控来跟踪更改系统时间​​settimeofday​​，​​clock_adjtime​​和其他时间相关的系统调用。

**记录用户运行的命令:** 由于审计可以跟踪文件是否已被执行，因此可以定义许多规则来记录特定命令的每次执行。例如，可以为​​/bin​​目录中的每个可执行文件定义规则。然后可以通过用户 ID 搜索生成的日志条目，以生成每个用户执行命令的审计跟踪。

**记录安全事件:** 该​​pam_faillock​​认证模块能够记录失败的登录尝试的。还可以设置审核以记录失败的登录尝试，并提供有关尝试登录的用户的其他信息。

**搜索事件:** Audit 提供了ausearch实用程序，该实用程序可用于过滤日志条目并根据许多条件提供完整的审计跟踪。

**运行摘要报告:** 该aureport实用程序可用于生成，除其他事项外，记录的事件每日报告。然后系统管理员可以分析这些报告并进一步调查可疑活动。

**监控网络访问:** iptables和ebtables实用程序可以被配置为触发审计事件，从而允许系统管理员监控网络访问

## 审计系统架构

审计系统由两个主要部分组成：用户空间应用程序和实用程序，以及内核端系统调用处理。内核组件接收来自用户空间应用程序的系统调用，并通过三个过滤器之一过滤它们：user、task或exit。一旦系统调用通过这些过滤器之一，它就会通过排除过滤器发送，排除过滤器根据审核规则配置将其发送到审核守护程序以进行进一步处理。

用户空间审计守护进程从内核收集信息并在日志文件中创建日志文件条目。其他审计用户空间实用程序与审计守护进程、内核审计组件或审计日志文件交互：

    audisp — 审计调度程序守护进程与审计守护进程交互并将事件发送到其他应用程序以进行进一步处理。这个守护进程的目的是提供一个插件机制，以便实时分析程序可以与审计事件交互。
    auditctl — 审计控制实用程序与内核审计组件交互，以控制事件生成过程的许多设置和参数。
    其余的审计实用程序将审计日志文件的内容作为输入，并根据用户的要求生成输出。例如，aureport实用程序生成所有记录事件的报告。

## 安装审计包

CentOS7系统默认安装了audit服务

```bash

rpm -aq | grep audit
rpm -ql audit

#未安装，可以使用下面命令安装
yum install audit
systemctl start auditd
systemctl enable auditd
```

## 配置审计服务

审计守护进程可以在​​ /etc/audit/auditd.conf ​​配置文件中进行配置。此文件包含修改审核守护程序行为的配置参数。任何空行或井号 ( ​​#​​)后面的任何文本都将被忽略。

### 配置auditd CAPP环境

默认​​auditd​​配置应该适用于大多数环境。但是，如果您的环境必须满足受控访问保护配置文件(CAPP)设置的标准，这是通用标准认证的一部分，则必须使用以下设置配置审核守护程序：

- 保存审核日志文件的目录（通常为​​/var/log/audit/​​）应驻留在单独的分区上。这可以防止其他进程占用此目录中的空间，并为审计守护程序提供对剩余空间的准确检测。

- 该 **max_log_file​​** 参数指定单个审计日志文件的最大大小，必须设置为充分利用保存审计日志文件的分区上的可用空间。

- 该 **​​max_log_file_action​** ​参数决定一旦​**​max_log_file​​**达到设置的限制时采取的操作，应设置​​keep_logs​​为防止审计日志文件被覆盖。

- 该 **​​space_left​​** 参数指定磁盘上剩余的可用空间量，在该 **​​space_left_action** ​​参数中设置的操作将被触发，必须设置为一个数字，以便管理员有足够的时间来响应并释放磁盘空间。该​ **​space_left** 值取决于生成审核日志文件的速率。

- 建议将 **​​space_left_action​​** 参数设置为​​email​​或​​exec​​使用适当的通知方法。

- 该 **​​admin_space_left​** ​参数指定  **​​admin_space_left_action​** 触发参数中设置的操作的绝对最小可用空间量，必须设置为一个值，以便留出足够的空间来记录管理员执行的操作。

- 该 **​​admin_space_left_action​​** 参数必须设置为​​single​​使系统进入单用户模式并允许管理员释放一些磁盘空间。

- 该 **​​disk_full_action** 参数指定在保存审核日志文件的分区上没有可用空间时触发的操作，必须设置为​​halt​​或​​single​​。这可确保系统在 Audit 无法再记录事件时关闭或以单用户模式运行。

- **​​disk_error_action​​** ，其中规定，被触发的情况下，上保存审计日志文件的分区检测到错误的动作，必须设置为​​syslog​​，​​single​​或​​halt​​，这取决于你的本地安全策略有关硬件故障的处理。

- 所述 **​​flush​​** 配置参数必须设置为​​sync​​或​​data​​。这些参数确保所有审计事件数据与磁盘上的日志文件完全同步。

其余配置选项应根据您的本地安全策略进行设置

## 定义审计规则

审计系统根据一组规则运行，这些规则定义了要在日志文件中捕获的内容。可以指定三种类型的审计规则：

    - 控制规则 — 允许修改审计系统的行为及其某些配置。
    - 文件系统规则——也称为文件监视，允许审计对特定文件或目录的访问。
    - 系统调用规则——允许记录任何指定程序进行的系统调用。

可以使用 **auditctl** 实用程序在命令行上指定审计规则（请注意，这些规则在重新启动后不会持久），或写入​​/etc/audit/audit.rules​​文件(持久化保存)。以下两节总结了定义审计规则的两种方法

### 使用auditctl实用程序定义审计规则

​与审计服务和审计日志文件交互的所有命令都需要 root 权限。确保以 root 用户身份执行这些命令。​​

该​​auditctl​​命令允许您控制审计系统的基本功能并定义决定记录哪些审计事件的规则。

#### 定义控制规则

以下是一些允许您修改审计系统行为的控制规则：

    -b
    设置内核中现有审计缓冲区的最大数量，例如：
    auditctl -b 8192

    -f
    auditctl -f 2
    上述配置会在发生严重错误时触发内核恐慌。

    -e
    auditctl -e 2

    -r
    设置每秒生成消息的速率，例如：
    auditctl -r 0
    上述配置对生成的消息没有设置速率限制。

    -s
    报告审计系统的状态，例如：
    [root@proxy ~]# auditctl -s
    enabled 1 
    failure 2 
    pid 5613 
    rate_limit 0 
    backlog_limit 8192 
    lost 0 
    backlog 0 
    loginuid_immutable 0 unlocked

    -l
    列出所有当前加载的审计规则，例如：
    [root@proxy ~]# auditctl -l
    No rules

    -D
    删除所有当前加载的审计规则，例如:
    [root@proxy ~]# auditctl -D
    No rules 

#### 定义文件系统规则

语法:

```bash
​​auditctl -w path_to_file -p permission -k key_name​​
```

解释:

    path_to_file：被审计的文件或目录

    权限:
    ​​r​​—对文件或目录的读取权限
    ​​w​​—对文件或目录的写访问权限
    ​​x​​—执行对文件或目录的访问
    ​​a​​—更改文件或目录的属性

    key_name: 是一个可选字符串，可帮助您识别生成特定日志条目的规则或规则集

例如:

    要定义记录对/etc/passwd文件的所有写访问和每个属性更改的规则，请执行以下命令：
    auditctl -w /etc/passwd -p wa -k passwd_change

    请注意，-k选项后面的字符串是任意的。
    要定义一个规则来记录/etc/selinux/目录中所有文件的所有写访问权限和每个属性更改，请执行以下命令：
    auditctl -w /etc/selinux/ -p wa -k selinux_change

    要定义记录/sbin/insmod命令执行的规则，将模块插入 Linux 内核，请执行以下命令：
    auditctl -w /sbin/insmod -p x -k module_insertion

#### 定义系统调用规则

语法:

```
​​auditctl -a action,filter -S system_call -F field=value -k key_name​​
```

解释:

    action 和filter 指定何时记录某个事件。action可以是always或nerver。filter指定将哪个内核规则匹配过滤器应用于事件。规则的匹配滤波器可以是以下中的一个：task、exit、user、exclude。

    system_call 通过名称指定系统调用。可以在/usr/include/asm/unistd_64.h文件中找到所有系统调用列表。多个系统调用可以组合成一个规则，每个都在-S选项后指定

    filed=value 指定其他选项，这些选项进一步修改规则以根据指定的体系结构、组ID、进程ID等匹配事件。

    key_name 是一个可选字符串，可帮助我们识别生成特定日志条目的规则或规则集。

例如:

    要定义一个规则，在程序每次使用adjtimex或settimeofday系统调用时创建日志条目，并且系统使用 64 位架构，请执行以下命令:
    auditctl -a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time_change

    定义一个规则，每次文件被ID为500或更大的系统用户删除或重命名时创建一个日志条目（该-F auid!=4294967295选项用于排除未设置登录UID的用户），执行以下命令:
    auditctl -a always,exit -S unlink -S unlinkat -S rename -S renameat -F "auid>=500" -F auid!="4294967295" -k delete

    也可以使用系统调用规则语法定义文件系统规则。以下命令为系统调用创建一个类似于-w /etc/shadow -p wa文件系统规则的规则:
    auditctl -a always,exit -F path=/etc/shadow -F perm=wa 

### 在 ​​/etc/audit/audit.rules 文件中定义持久审计规则和控制

要定义在重新启动后持续存在的审核规则，您必须将它们包含在​ **​/etc/audit/audit.rules** ​​文件中。此文件使用相同的​​auditctl​​命令行语法来指定规则。任何空行或井号 ( ​​#​​)后面的任何文本都将被忽略。

该​​auditctl​​命令还可用于从带有​​-R​​选项的指定文件中读取规则，例如：

```
auditctl -R /usr/share/doc/audit-2.8.5/rules/xxx.rules
```

#### 定义控制规则

一个文件可以只包含修改审计系统的行为如下控制规则：​​-b​​，​​-D​​，​​-e​​，​​-f​​，和​​ -r​​

```
# 删除之前的所有规则
-D

# 设置缓冲区大小
-b 8192

# 使配置不可变——需要重启才能更改审计规则
-e 2

# 发生故障时的恐慌
-f 2

# 每秒最多生成 100 条审计消息
-r 100

```

#### 定义文件系统和系统调用规则

文件系统和系统调用规则是使用​​auditctl​​语法定义的

例如: 文件系统和系统调用规则​ ​audit.rules​​

    -w /etc/passwd -p wa -k passwd_changes
    -w /etc/selinux/ -p wa -k selinux_changes
    -w /sbin/insmod -px -k module_insertion

    -a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time_change
    -a always,exit -S unlink -S unlinkat -S rename -S renameat -F auid>=500 -F auid!=4294967295

#### 预配置的规则文件

在目录中，审计包根据各种认证标准提供了一组预配置的规则文件: **​/usr/share/doc/audit-*[version]*/rules​​/**

    ​​nispom.rules​​ ——符合《国家工业安全方案操作手册》第八章要求的审计规则配置。

    ​​capp.rules​​— 满足​ ​受控访问保护配置文件​​(CAPP)设置的要求的审计规则配置，这是通用标准认证的一部分。

    ​​lspp.rules​​— 符合​ ​标记安全保护配置文件​​(LSPP)设置要求的审计规则配置，这是通用标准认证的一部分。

    ​​stig.rules​​ — 符合安全技术实施指南 (STIG) 规定要求的审计规则配置。

## 安全等保中较常用配置

```
​​vim /etc/audit/rules.d/audit.rules​​

-a exit,always -F arch=b64 -S umask -S chown -S chmod 
-a exit,always -F arch=b64 -S unlink -S rmdir 
-a exit,always -F arch=b64 -S setrlimit 
-a exit,always -F arch=b64 -S setuid -S setreuid 
-a exit,always -F arch=b64 -S setgid -S setregid 
-a exit,always -F arch=b64 -S sethostname -S setdomainname 
-a exit,always -F arch=b64 -S adjtimex -S settimeofday 
-a exit,always -F arch=b64 -S mount -S _sysctl

-w /etc/group -p wa 
-w /etc/passwd -p wa 
-w /etc/shadow -p wa 
-w /etc/sudoers -p wa

-w /etc/ssh/sshd_config

-w /etc/bashrc -p wa   
-w /etc/profile -p wa   
-w /etc/profile.d/   
-w /etc/aliases -p wa   
-w /etc/sysctl.conf -p wa

-w /var/log/lastlog

# Disable adding any additional rules - note that adding *new* rules will require a reboot
```
