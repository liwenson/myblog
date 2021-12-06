---
title: ansible安装脚本
date: 2021-10-29 11:52
categories:
- linux
tags:
- ansible
---
	
	
摘要: ansible安装脚本
<!-- more -->


```
#!/bin/bash 
# 
############################################# 
# author:yd 
# describes:自动化安装和配置ansible 
# version:v1.0 
# updated:2021313 
############################################# 
# 
# 主机列表文件 
hostfile='/root/hosts'
# 错误信息以红色显示 
_err() 
{ 
	echo -e "\033[1;31m[ERROR] $1\033[0m"
} 
# 一般信息以绿色显示 
_info() 
{ 
	echo -e "\033[1;32m[Info] $1\033[0m"
} 
# 仅限指定用户运行本脚本 
if [ $EUID != "0" ];then
	_err "please use root run script!!!"
	exit 1 
fi
rpm -qa|grep ansible 
if [ $? -eq 0 ];then
	_err "ansible is already exists,exit..."
	exit 1 
fi
if [ -e $hostfile ];then
	yum list|grep ansible 
	if [ $? -ne 0 ];then
		_err "there are no packages of ansible in the repository,exit..."
		exit 1 
	else
		yum install ansible -y 
		if [ $? -eq 0 ];then
			_info "the ansible installation successful!"
			sed -i "s@\#host_key_checking = False@host_key_checking = False@g" /etc/ansible/ansible.cfg 
			sed -i "s@\#log_path = \/var\/log\/ansible.log@log_path = \/var\/log\/ansible.log@g" /etc/ansible/ansible.cfg 
			cp $hostfile /etc/ansible/hosts
			_info "$hostfile copy to /etc/ansible/ successful!"
			ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa
			_info "please input passwd to the host list $hostfile："
			ansible all -m authorized_key -a "user=root key='{{ lookup('file', '/root/.ssh/id_rsa.pub') }}' path=/root/.ssh/authorized_keys manage_dir=no" --ask-pass -c paramiko 
			sed -i "s@\#private_key_file = \/path\/to\/file@private_key_file = \/root\/.ssh\/id_rsa@g" /etc/ansible/ansible.cfg 
			_info "ansible installed successed!"
		else
			_err "the ansible installation failed,please update yum tools and try again!"
		fi
	fi
else
	_err "$hostfile file is not found,please check it！"
	exit 1 
fi
```