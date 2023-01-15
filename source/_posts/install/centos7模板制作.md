---
title: cento7虚拟机模板制作
date: 2021-05-08 10:10
categories:
- centos7
tags:
- centos7
---
  
  
摘要: 系统镜像模板的制作
<!-- more -->

## 安装QEMU Guest Agent

```bash
# 安装qemu agent
dnf install -y qemu-guest-agent
或
apt-get install qemu-guest-agent
或
yum install qemu-guest-agent

reboot
```

安装重启后，确保在[概要]中可以看到对应IP信息，如果无法看到对应IP信息，说明QEMU Guest Agent未启用，需要在[选项]中启用。(需要虚拟化平台支持)

## 系统初始化设置

```bash
# 更新系统
dnf update

# 设置首次登录强制修改密码
chage -d0 root

# 删除网卡配置文件
rm -rf /etc/sysconfig/network-scripts/ifcfg-ens*

# 删除SSH私钥，不同系统私钥从严格意思上来说应该不同，所以删除后，重启系统会自动生成全新的私钥
rm -rf /etc/ssh/ssh_host_*

# 修改machine-id，machine-id为系统的唯一性ID，每台服务器系统应该唯一，用于解决系统ID冲突，我们需要重置机器ID。先删除现有/etc/machine-id文件，然后在/etc/profile文件最后添加systemd-machine-id-setup命令，开机后会通过systemd-machine-id-setup命令生成全新的machine-id。如果/etc/machine-id文件存在，systemd-machine-id-setup命令就不会再重新创建新的机器ID。
rm -rf /etc/machine-id
echo "systemd-machine-id-setup" >> /etc/profile

# 清理系统日志
systemctl stop systemd-journald.socket
find /var/log -type f -exec rm -rf {} \;

# 设置持久化保存日志的目录
mkdir -p /var/log/journal

# 清除历史命令
echo /dev/null > ~/.bash_history ; history -c

# 关闭系统
systemctl poweroff
```


系统就封装完成了，这时候只需要在Proxmox VE右击对应虚拟机转换成模板即可。此方法不仅仅适用于Proxmox VE，对于Hyper-v\ESXI\OpenStack\oVirt同样适用，只是Hyper-v与ESXI安装的代理软件包不同而已，如：vm-tools\增强会话等。通过模板的构建，可以极大提高我们部署系统的速度。下篇预告：在Rocky Linux 8.3 RC1 上安装Docker CE。
不同的虚拟化平台需要安装不同的代理软件包