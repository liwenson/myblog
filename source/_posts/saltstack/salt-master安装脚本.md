---
title: salt-master 安装脚本
date: 2020-09-21 12:42
categories:
- salt
tags:
- salt
---

```bash
#!/bash/sh
#Function: install salt-master 
echo -e "\033[1;32m ###########  close selinux ############# \033[0m"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
systemctl stop firewalld.service
systemctl disable firewalld.service
sleep 5
echo -e "\033[1;32m ###########  install salt-master ############# \033[0m"
curl -L https://bootstrap.saltstack.com -o install_salt.sh
sh install_salt.sh -P -M

tdate=`date '+%m%d%H%M%S'`
cp /etc/salt/master /etc/salt/master_bak-$tdate

sed -i '/^interface:/interface: 0.0.0.0' /etc/salt/master
sed -i 's/#auto_accept: False/auto_accept: True/g' /etc/salt/master
```

