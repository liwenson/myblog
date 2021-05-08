---
title: Centos7系统优化脚本
date: 2020-09-21 12:40
categories:
- centos7
tags:
- 优化
---

```bash
#!/bin/bash

set -e

init_yum(){
echo -e "\033[1;32m ###########  初始化yum 源 ############# \033[0m"
cd /etc/yum.repos.d/
[[ ! -d repo ]] && mkdir -p repo || echo "已存在"
\mv -f Cent* repo
# aliyun
curl -s -O  http://mirrors.aliyun.com/repo/Centos-7.repo
# 163
curl -s -O http://mirrors.163.com/.help/CentOS7-Base-163.repo

# 安装epel源
yum install -y epel-release
# 安装aliyun epel源
curl -o /etc/yum.repos.d/epel-7.repo http://mirrors.aliyun.com/repo/epel-7.repo

# 清除系统所有的yum缓存
yum clean all
# 生成yum缓存
yum makecache

# 查看系统可用的yum源和所有的yum源
yum repolist enabled
cd -

sleep 1
echo -e "\033[1;32m ###########  初始化yum 源 完成 ############# \033[0m"
}

init_ntp(){
echo -e "\033[1;32m ###########  时间同步  ############# \033[0m"
if [ !$(rpm -qa | grep ntp-) ];then
yum install ntp -y
fi

cat >/etc/ntp.conf<<EOF
driftfile /var/lib/ntp/drift
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1 
restrict ::1
server cn.ntp.org.cn iburst
server ntp.aliyun.com iburst
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
EOF

systemctl start ntpd
systemctl enable ntpd
systemctl status ntpd
}


function ulimits(){
cat > /etc/security/limits.conf <<EOF
* soft noproc 20480
* hard noproc 20480
root soft nofile 65536
root hard nofile 65536
* soft nofile 65536
* hard nofile 65536
EOF
ulimit -n 65536
ulimit -u 20480
#echo "[ulimits 配置] ==> OK"
}

init_selinux(){
echo -e "\033[1;32m 禁用SELinux / 关闭防火墙  ############# \033[0m"
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
setenforce 0

sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

yum install -y openssl openssh bash

systemctl  restart sshd.service
systemctl stop firewalld.service
systemctl disable firewalld.service
}

init_sysctl(){
echo -e "\033[1;32m ###########  内核参数优化  ############# \033[0m"

cat >> /etc/sysctl.conf << EOF
#CTCDN系统优化参数
#关闭ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
#决定检查过期多久邻居条目
net.ipv4.neigh.default.gc_stale_time=120
#使用arp_announce / arp_ignore解决ARP映射问题
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.all.arp_announce=2
net.ipv4.conf.lo.arp_announce=2
# 避免放大攻击
net.ipv4.icmp_echo_ignore_broadcasts = 1
# 开启恶意icmp错误消息保护
net.ipv4.icmp_ignore_bogus_error_responses = 1
#关闭路由转发
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
#开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
#处理无源路由的包
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
#关闭sysrq功能
kernel.sysrq = 0
#core文件名中添加pid作为扩展名
kernel.core_uses_pid = 1
# 开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 1
#修改消息队列长度
kernel.msgmnb = 65536
kernel.msgmax = 65536
#设置最大内存共享段大小bytes
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
#timewait的数量，默认180000
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096        87380   4194304
net.ipv4.tcp_wmem = 4096        16384   4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
#每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog = 262144
#限制仅仅是为了防止简单的DoS 攻击
net.ipv4.tcp_max_orphans = 3276800
#未收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
#内核放弃建立连接之前发送SYNACK 包的数量
net.ipv4.tcp_synack_retries = 1
#内核放弃建立连接之前发送SYN 包的数量
net.ipv4.tcp_syn_retries = 1
#启用timewait 快速回收
net.ipv4.tcp_tw_recycle = 1
#开启重用。允许将TIME-WAIT sockets 重新用于新的TCP 连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
#当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
#允许系统打开的端口范围
net.ipv4.ip_local_port_range = 1024    65000
# 确保无人能修改路由表
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
EOF
/sbin/sysctl -p

}

init_vim(){
echo -e "\033[1;32m ###########  初始化vim 配置  ############# \033[0m"

if [ !$(rpm -q vim-common) ];then
yum install vim -y
fi
echo 'alias vi=vim' >> /etc/profile
echo 'stty erase ^H' >> /etc/profile
cat >> /root/.vimrc << EOF
set tabstop=4
set shiftwidth=4
set expandtab
syntax on
"set number
EOF

}


function other(){
yum groupinstall Development tools -y >/dev/null 2>&1
yum install -y vim wget lrzsz telnet traceroute iotop tree >/dev/null 2>&1
yum install -y ncftp axel git zlib-devel openssl-devel unzip xz libxslt-devel libxml2-devel libcurl-devel >/dev/null 2>&1
}

function history(){
if ! grep "HISTTIMEFORMAT" /etc/profile >/dev/null 2>&1
then echo '
UserIP=$(who -u am i | cut -d"("  -f 2 | sed -e "s/[()]//g")
export HISTTIMEFORMAT="[%F %T] [`whoami`] [${UserIP}] " ' >> /etc/profile;
fi
#echo "[history 优化] ==> OK"
}

platform=$(uname -i)
if [ ${platform} != "x86_64" ];then
echo "这个脚本只能优化 64位系统"
exit 1
fi

init_yum
init_ntp
init_selinux
ulimits
other
history
init_vim
init_sysctl

cat << EOF
+-------------------------------------------------+
|                优 化 已 完 成             |
|             5s 后 重启 这台服务器 !       |
+-------------------------------------------------+
EOF

sleep 5

reboot
```



jdk 环境变量

```
/etc/profile.d/jdk.sh

JAVA_HOME=/opt/jdk1.8.0_221
CLASSPATH=${JAVA_HOME}/lib/
PATH=$PATH:${JAVA_HOME}/bin
export PATH JAVA_HOME CLASSPAT
```

