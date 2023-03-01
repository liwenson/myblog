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

使用Lynis进行的典型扫描过程:
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

### 方式一

[下载压缩包页面](https://cisofy.com/downloads/lynis/)

```bash
mkdir -p /usr/local/lynis
cd /usr/local/lynis
```

从 Lynis 下载页面，将链接复制到 Lynis tarball（以 lynis-<version>.tar.gz 结尾）。

将此链接与 一起使用 wget （通常默认安装） 。 macOS 用户可以使用 curl 工具，BSD 用户可以使用 fetch 。

```bash
curl https://cisofy.com/files/lynis-<version>.tar.gz -o lynis.tar.gz

tar xfvz lynis-<version>.tar.gz
```

#### 方式二

**Git**

```
git clone https://github.com/CISOfy/lynis
```

#### 方式三

Red Hat

```bash
yum install lynis
```

Debian

```bash
apt-get install lynis
```

openSUSE

```bash
zypper install lynis
```

macOS

```bash
brew install lynis
```

## 使用

### 常用的选项

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

### 要查看 Lynis 中所有可用的命令:

```bash
./lynis show commands
```

### 显示其状态以及如何启动的建议

```bash
cd lynis

./lynis
```

### 运行系统审查

```bash
./lynis audit system
```

### 查看扫描类别

```bash
lynis show groups
```

### 指定类别扫描

```bash
./lynis --tests-from-group "group name"
```

```bash
./lynis --tests-from-group "php ssh"
```

### 审查恶意软件

```bash
lynis --tests-from-group "hardening malware" 需要安装malware scanner才能完成这个功能

```

[Lynis control HRDN-7230: Presence malware scanner - CISOfy](https://cisofy.com/lynis/controls/HRDN-7230/)

### 查看扫描详情

在每项suggestion和warning后有test_id

通过 `lynis show tests` 查看所有test_id

**查看详细**

```bash
./lynis show details PHP-237
```

### 审计模块明细表

```bash
./lynis show tests
```

### 查看日志与数据文件

默认路径

```
  Files:
  - Test and debug information      : /var/log/lynis.log
  - Report data                     : /var/log/lynis-report.dat
```

检查告内容:
```bash
grep Warning /var/log/lynis.log
more /var/log/lynis.log|grep Warning
more /var/log/lynis.log|grep Suggestion
```

检查建议内容:
```bash
grep Suggestion /var/log/lynis.log
```

### 检查更新

```bash
./lynis update info
```

### Lynis 使用颜色编码使报告更容易解读

    绿色。一切正常
    黄色。跳过、未找到，可能有个建议
    红色。你可能需要仔细看看这个

## 配置

默认lynis自带一个名为 default.prf 的默认配置文件

```bash
/etc/lynis/default.prf


git 方式安装的在lynis 目录下面
```

无需直接修改这个默认的配置文件，只需要新增一个 `custom.prf`  文件将自定义的信息加入其中就可以了。

如果要确认使用了什么配置文件，请使用 “show profile” 命令

```bash
./lynis show profiles
```

查看设置。可以选择添加–brief 和 –nocolors 仅显示设置。

```bash
./lynis show settings
```

### 自定义配置文件

```bash
touch custom.prf
```

然后将首选选项复制到您的自定义配置文件

### 从命令行配置设置

```bash
./lynis configure settings debug=yes
```

要更改多个设置，请使用冒号将它们分开。

```bash
./lynis configure settings debug=yes:quick=yes
```

确认是否使用 show settings 命令获取了新设置。

```bash
./lynis show settings
```

## 插件

### 目的

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

### 插件位置

第一步是了解 Lynis 的安装位置，尤其是插件存储在哪个目录中。

```bash
lynis show plugindir
```

注意：运行 Lynis 时，该路径也会显示在屏幕上，并存储在您的日志文件（通常为 /var/log/lynis.log）中。

### 官方插件库

[Lynis plugins - CISOfy](https://cisofy.com/lynis/plugins/)

### 自定义插件

[官方开发文档](https://cisofy.com/documentation/lynis/plugins/development/)

## 自动化对系统审核

```system
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

Create timer unit (/etc/systemd/system/lynis.timer)

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

## CentOS7一键安全加固及系统优化脚本

init_centos7.sh 脚本内容如下 脚本说明：本脚本在 <https://github.com/vtrois/spacepack上下载，并在其脚本基础上做了调整，根据前期CentOS7安全加固系列文章，添加了部分加固项>

```sh

#!/usr/bin/env bash
#
# Author:       Seaton Jiang <seaton@vtrois.com>
# Github URL:   https://github.com/vtrois/spacepack
# License:      MIT
# Date:         2020-08-13

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

RGB_DANGER='\033[31;1m'
RGB_WAIT='\033[37;2m'
RGB_SUCCESS='\033[32m'
RGB_WARNING='\033[33;1m'
RGB_INFO='\033[36;1m'
RGB_END='\033[0m'

CHECK_CENTOS=$( cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/' )
CHECK_RAM=$( cat /proc/meminfo | grep "MemTotal" | awk -F" " '{ram=$2/1000000}{printf("%.0f",ram)}' )

LOCK=/var/log/init_centos7_record.log

tool_info() {
    echo -e "========================================================================================="
    echo -e "                              Init CentOS 7 Script                                       "
    echo -e "          For more information please visit https://github.com/vtrois/spacepack          "
    echo -e "========================================================================================="
}

check_root(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RGB_DANGER}This script must be run as root!${RGB_END}"
        exit 1
    fi
}

check_lock() {
    if [ ! -f "$LOCK" ];then
        touch $LOCK
    else
        echo -e "${RGB_DANGER}Detects that the initialization is complete and does not need to be initialized any further!${RGB_END}"
        exit 1
    fi
}

check_os() {
    if [ "${CHECK_CENTOS}" != '7' ]; then
        echo -e "${RGB_DANGER}This script must be run in CentOS 7!${RGB_END}"
        exit 1
    fi
}

new_swap() {
    echo "============= swap =============" >> ${LOCK} 2>&1
    if [ "${CHECK_RAM}" -le '2' ]; then
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    dd if=/dev/zero of=/swapfile bs=1024 count=1048576 >> ${LOCK} 2>&1
    chmod 600 /swapfile >> ${LOCK} 2>&1
    mkswap /swapfile >> ${LOCK} 2>&1
    swapon /swapfile >> ${LOCK} 2>&1
    echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
    echo '# Swap' >> /etc/sysctl.conf
    echo 'vm.swappiness = 10' >> /etc/sysctl.conf
    sysctl -p >> ${LOCK} 2>&1
    sysctl -n vm.swappiness >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
    else
    echo -e "${RGB_SUCCESS}Skip, no configuration needed${RGB_END}"
    fi
}

open_bbr() {
    echo "============= bbr =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    echo "# BBR" >> /etc/sysctl.conf
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p >> ${LOCK} 2>&1
    sysctl -n net.ipv4.tcp_congestion_control >> ${LOCK} 2>&1
    lsmod | grep bbr >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

disable_software() {
    echo "============= selinux firewalld =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    setenforce 0 >> ${LOCK} 2>&1
    sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
    systemctl disable firewalld.service >> ${LOCK} 2>&1
 systemctl stop firewalld.service >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

time_zone() {
    echo "============= time zone =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    rm -rf /etc/localtime >> ${LOCK} 2>&1
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime >> ${LOCK} 2>&1
    ls -ln /etc/localtime >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

custom_profile() {
    echo "============= custom profile =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    cat > /etc/profile.d/centos7init.sh << EOF
PS1="\[\e[37;40m\][\[\e[32;40m\]\u\[\e[37;40m\]@\h \[\e[35;40m\]\W\[\e[0m\]]\\\\$ "
GREP_OPTIONS="--color=auto"
alias l='ls -AFhlt'
alias grep='grep --color'
alias egrep='egrep --color'
alias fgrep='fgrep --color'
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S  "
EOF
    cat /etc/profile.d/centos7init.sh >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

adjust_ulimit() {
    echo "============= adjust ulimit =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    sed -i '/^# End of file/,$d' /etc/security/limits.conf
    cat >> /etc/security/limits.conf <<EOF
# End of file
* soft core unlimited
* hard core unlimited
* soft nproc 1000000
* hard nproc 1000000
* soft nofile 1000000
* hard nofile 1000000
root soft core unlimited
root hard core unlimited
root soft nproc 1000000
root hard nproc 1000000
root soft nofile 1000000
root hard nofile 1000000
EOF
    cat /etc/security/limits.conf >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

kernel_optimum() {
    echo "============= kernel optimum =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    [ ! -e "/etc/sysctl.conf_bak" ] && /bin/mv /etc/sysctl.conf{,_bak}
    cat > /etc/sysctl.conf << EOF
# Controls source route verification
net.ipv4.conf.default.rp_filter = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0 
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.log_martians = 1 
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.all.promote_secondaries = 1
net.ipv4.conf.default.promote_secondaries = 1

# Controls the use of TCP syncookies
# Number of pid_max
kernel.core_uses_pid = 1
kernel.pid_max = 1000000
net.ipv4.tcp_syncookies = 1

# Controls the maximum size of a message, in bytes
# Controls the default maxmimum size of a mesage queue
# Controls the maximum shared segment size, in bytes
# Controls the maximum number of shared memory segments, in pages
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
kernel.sysrq = 1
kernel.softlockup_panic = 1
kernel.printk = 5

# TCP kernel paramater
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1

# Socket buffer
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 32768
net.core.somaxconn = 65535
net.core.optmem_max = 81920

# TCP conn
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 15

# TCP conn reuse
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 5
net.ipv4.tcp_max_tw_buckets = 7000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_synack_retries = 1

# keepalive conn
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.ip_local_port_range = 1024 65535

net.ipv6.neigh.default.gc_thresh3 = 4096
net.ipv4.neigh.default.gc_thresh3 = 4096
EOF
    sysctl -p >> ${LOCK} 2>&1
    cat /etc/sysctl.conf >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}


updatedb_optimum() {
    echo "============= updatedb optimum =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    sed -i 's,media,media /data,' /etc/updatedb.conf
    cat /etc/updatedb.conf >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

open_ipv6() {
    echo "============= open ipv6 =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    echo '# IPV6' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.all.disable_ipv6=0' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.default.disable_ipv6=0' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.lo.disable_ipv6=0' >> /etc/sysctl.conf
    sysctl -p >> ${LOCK} 2>&1
    cat /etc/sysctl.conf >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

disable_cad() {
    echo "============= disable cad =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    systemctl mask ctrl-alt-del.target >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

remove_users() {
    echo "============= remove users =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    for u in adm lp sync shutdown halt mail operator games ftp 
    do
    userdel ${u} >> ${LOCK} 2>&1
    done
    cut -d : -f 1 /etc/passwd >> ${LOCK} 2>&1
    for g in adm lp mail games ftp 
    do
    groupdel ${g} >> ${LOCK} 2>&1
    done
    cat /etc/group >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

sys_permissions() {
    echo "============= sys permissions =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    chmod 644 /etc/passwd >> ${LOCK} 2>&1
    chmod 644 /etc/group >> ${LOCK} 2>&1
    chmod 000 /etc/shadow >> ${LOCK} 2>&1
    chmod 000 /etc/gshadow >> ${LOCK} 2>&1
    ls -la /etc/passwd >> ${LOCK} 2>&1
    ls -la /etc/group >> ${LOCK} 2>&1
    ls -la /etc/shadow >> ${LOCK} 2>&1
    ls -la /etc/gshadow >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

password_policy() {
    echo "============= password policy =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    sed -i 's/^PASS_MAX_DAYS.*$/PASS_MAX_DAYS   90/' /etc/login.defs
    sed -i 's/^PASS_MIN_DAYS.*$/PASS_MIN_DAYS   10/' /etc/login.defs
    cat /etc/login.defs >> ${LOCK} 2>&1
    cat >>/etc/security/pwquality.conf << EOF
minlen = 8 
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
EOF
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

change_useradd() {
    echo "============= change useradd =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    sed -i 's/^INACTIVE.*$/INACTIVE=180/' /etc/default/useradd
    cat /etc/default/useradd >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

sec_ssh() {
    echo "============= sec ssh =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    sed -i 's/UseDNS.*$/UseDNS no/' /etc/ssh/sshd_config
    sed -i 's/^#LoginGraceTime.*$/LoginGraceTime 60/' /etc/ssh/sshd_config
    sed -i 's/^#PermitEmptyPasswords.*$/PermitEmptyPasswords no/' /etc/ssh/sshd_config
    sed -i 's/^#PubkeyAuthentication.*$/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#MaxAuthTries.*$/MaxAuthTries 3/' /etc/ssh/sshd_config
    sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 30/g" /etc/ssh/sshd_config 
    sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 3/g" /etc/ssh/sshd_config
    sed -i "s/X11Forwarding yes/X11Forwarding no/g" /etc/ssh/sshd_config
    sed -i "s/#Banner none/Banner \/etc\/issue.net/g" /etc/ssh/sshd_config
    echo "Authorized users only. All activity may be monitored and reported.">/etc/issue.net
    systemctl restart sshd.service >> ${LOCK} 2>&1
    cat /etc/ssh/sshd_config >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

timeout_config() {
    echo "============= timeout config =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    echo "export TMOUT=1800" >> /etc/profile.d/centos7init.sh
    cat /etc/profile.d/centos7init.sh >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}

lockout_policy() {
    echo "============= lockout policy =============" >> ${LOCK} 2>&1
    echo -en "${RGB_WAIT}Configuring...${RGB_END}"
    [ ! -e "/etc/pam.d/system-auth_bak" ] && /bin/mv /etc/pam.d/system-auth{,_bak}
    cat > /etc/pam.d/system-auth << EOF
auth        required                                     pam_env.so
auth        required                                     pam_faillock.so preauth silent audit deny=3 unlock_time=300
auth        required                                     pam_faildelay.so delay=2000000
auth        [default=1 ignore=ignore success=ok]         pam_succeed_if.so uid >= 1000 quiet
auth        [default=1 ignore=ignore success=ok]         pam_localuser.so
auth        sufficient                                   pam_unix.so nullok try_first_pass
auth        [default=die]                                pam_faillock.so  authfail  audit  deny=3  unlock_time=300
auth        requisite                                    pam_succeed_if.so uid >= 1000 quiet_success
auth        sufficient                                   pam_sss.so forward_pass
auth        required                                     pam_deny.so

account     required                                     pam_unix.so
account     sufficient                                   pam_localuser.so
account     sufficient                                   pam_succeed_if.so uid < 1000 quiet
account     [default=bad success=ok user_unknown=ignore] pam_sss.so
account     required                                     pam_permit.so
account     required                                     pam_faillock.so

password    requisite                                    pam_pwquality.so try_first_pass local_users_only
password    sufficient                                   pam_unix.so sha512 shadow nullok try_first_pass use_authtok
password    sufficient                                   pam_sss.so use_authtok
password    required                                     pam_deny.so

session     optional                                     pam_keyinit.so revoke
session     required                                     pam_limits.so
-session    optional                                     pam_systemd.so
session     [success=1 default=ignore]                   pam_succeed_if.so service in crond quiet use_uid
session     required                                     pam_unix.so
session     optional                                     pam_sss.so
EOF
    [ ! -e "/etc/pam.d/password-auth_bak" ] && /bin/mv /etc/pam.d/password-auth{,_bak}
    cat > /etc/pam.d/password-auth << EOF
auth        required                                     pam_env.so
auth        required                                     pam_faillock.so preauth silent audit deny=3 unlock_time=300
auth        required                                     pam_faildelay.so delay=2000000
auth        [default=1 ignore=ignore success=ok]         pam_succeed_if.so uid >= 1000 quiet
auth        [default=1 ignore=ignore success=ok]         pam_localuser.so
auth        sufficient                                   pam_unix.so nullok try_first_pass
auth        [default=die]                                pam_faillock.so  authfail  audit  deny=3  unlock_time=300
auth        requisite                                    pam_succeed_if.so uid >= 1000 quiet_success
auth        sufficient                                   pam_sss.so forward_pass
auth        required                                     pam_deny.so

account     required                                     pam_unix.so
account     sufficient                                   pam_localuser.so
account     sufficient                                   pam_succeed_if.so uid < 1000 quiet
account     [default=bad success=ok user_unknown=ignore] pam_sss.so
account     required                                     pam_permit.so
account     required                                     pam_faillock.so

password    requisite                                    pam_pwquality.so try_first_pass local_users_only
password    sufficient                                   pam_unix.so sha512 shadow nullok try_first_pass use_authtok
password    sufficient                                   pam_sss.so use_authtok
password    required                                     pam_deny.so

session     optional                                     pam_keyinit.so revoke
session     required                                     pam_limits.so
-session    optional                                     pam_systemd.so
session     [success=1 default=ignore]                   pam_succeed_if.so service in crond quiet use_uid
session     required                                     pam_unix.so
session     optional                                     pam_sss.so
EOF
    systemctl restart sshd.service >> ${LOCK} 2>&1
    cat /etc/pam.d/etc/pam.d/system-auth >> ${LOCK} 2>&1
    cat /etc/pam.d/password-auth >> ${LOCK} 2>&1
    echo -e "\r${RGB_SUCCESS}Configuration Success${RGB_END}"
}


reboot_os() {
    echo -e "\n${RGB_WARNING}Please restart the server and see if the services start up fine.${RGB_END}"
    echo -en "${RGB_WARNING}Do you want to restart OS ? [y/n]: ${RGB_END}"
    while :; do
        read REBOOT_STATUS
        if [[ ! "${REBOOT_STATUS}" =~ ^[y,n]$ ]]; then
            echo -en "${RGB_DANGER}Input error, please only input 'y' or 'n': ${RGB_END}"
        else
            break
        fi
    done
    [ "${REBOOT_STATUS}" == 'y' ] && reboot
}

main() {
    echo -e "\n${RGB_INFO}1/18 : Start Init CentOS7 Script ${RGB_END}"

    echo -e "\n${RGB_INFO}2/18 : Customize the profile (color and alias)${RGB_END}"
    custom_profile

    echo -e "\n${RGB_INFO}3/18 : Time zone adjustment${RGB_END}"
    time_zone

    echo -e "\n${RGB_INFO}4/18 : Disable selinux and firewalld${RGB_END}"
    disable_software

    echo -e "\n${RGB_INFO}5/18 : Disable Ctrl+Alt+Del${RGB_END}"
    disable_cad

    echo -e "\n${RGB_INFO}6/18 : Kernel parameter optimization${RGB_END}"
    kernel_optimum

    echo -e "\n${RGB_INFO}7/18 : The updatedb optimization${RGB_END}"
    updatedb_optimum

    echo -e "\n${RGB_INFO}8/18 : Adding swap space${RGB_END}"
    new_swap

    echo -e "\n${RGB_INFO}9/18 : Adjustment of ulimit${RGB_END}"
    adjust_ulimit
    
    echo -e "\n${RGB_INFO}10/18 : Enable tcp bbr congestion control algorithm${RGB_END}"
    open_bbr

    echo -e "\n${RGB_INFO}11/18 : Enable IPV6${RGB_END}"
    open_ipv6

    echo -e "\n${RGB_INFO}12/18 : Remove unnecessary users and user groups from the system${RGB_END}"
    remove_users

    echo -e "\n${RGB_INFO}13/18 : System permissions for sensitive files${RGB_END}"
    sys_permissions

    echo -e "\n${RGB_INFO}14/18 : Modify Account Password Survival Policy${RGB_END}"
    password_policy

    echo -e "\n${RGB_INFO}15/18 : Maximum number of days an account is valid after password expiration strategy${RGB_END}"
    change_useradd

    echo -e "\n${RGB_INFO}16/18 : Secure configuration of SSH${RGB_END}"
    sec_ssh

    echo -e "\n${RGB_INFO}17/18 : Timeout Auto-Logout Configuration${RGB_END}"
    timeout_config

    echo -e "\n${RGB_INFO}18/18 : Configure account login failure lockout policy${RGB_END}"
    lockout_policy


    reboot_os
}

clear
tool_info
check_root
check_os
check_lock
main
```
