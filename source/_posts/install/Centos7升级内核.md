---
title: Centos7内核升级
date: 2020-04-1 14:00:00
categories: 
- centos7
tags:
- update
---


## 内核下载

```txt
https://elrepo.org/linux/kernel/el7/x86_64/RPMS/
```

## 安装ELRepo到CentOS

```bash
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum install https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
```

## 添加 repository 后, 列出可以使用的kernel包版本**

```bash
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
```

## 安装需要的kernel版本，这里安装 kernel-lt

```bash
yum --enablerepo=elrepo-kernel install kernel-lt
```

内核版本介绍

- **lt**:longterm的缩写：长期维护版；
- **ml**:mainline的缩写：最新稳定版；

## 方式一

**检查kernel启动顺序**

默认启动的顺序是从0开始，新内核是从头插入（目前位置在0，而4.4.4的是在1），所以需要选择0。

```
grub2-set-default 0
```



### 删除老内核以及内核工具

```
rpm -qa|grep kernel|grep 3.10
rpm -qa|grep kernel|grep 3.10|xargs yum remove -y
```

### 安装新版本工具包

```
yum --disablerepo=\* --enablerepo=elrepo-kernel install -y kernel-ml-tools.x86_64

rpm -qa|grep kernel
```

**重新创建kernel配置**

```
 grub2-mkconfig -o /boot/grub2/grub.cfg
 
 
 reboot   # 重启
```



方式二：

####  查看系统上的所有可以内核

```
awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg

0 : CentOS Linux (4.15.6-1.el7.elrepo.x86_64) 7 (Core)
1 : CentOS Linux (3.10.0-514.26.2.el7.x86_64) 7 (Core)
2 : CentOS Linux (3.10.0-327.el7.x86_64) 7 (Core)
3 : CentOS Linux (0-rescue-f9d400c5e1e8c3a8209e990d887d4ac1) 7 (Core)
```

#### 通过 `grub2-set-default 0` 命令设置：

```
grub2-set-default 0


reboot  #重启
```





## 删除旧内核

#### 方式一，通过 `yum remove` 命令

```
查看系统中全部的内核：

# rpm -qa | grep kernel

kernel-tools-libs-3.10.0-514.26.2.el7.x86_64
kernel-ml-4.15.6-1.el7.elrepo.x86_64
kernel-3.10.0-327.el7.x86_64
kernel-tools-3.10.0-514.26.2.el7.x86_64
kernel-headers-3.10.0-514.26.2.el7.x86_64
kernel-3.10.0-514.26.2.el7.x86_64
```

删除旧内核的 RPM 包

```
yum remove kernel-tools-libs-3.10.0-514.26.2.el7.x86_64 kernel-3.10.0-327.el7.x86_64 kernel-tools-3.10.0-514.26.2.el7.x86_64 kernel-headers-3.10.0-514.26.2.el7.x86_64 kernel-3.10.0-514.26.2.el7.x86_64
```



#### 方式二，通过 `yum-utils` 工具

````
yum install yum-utils
````



#### 删除

```
package-cleanup --oldkernels
```

