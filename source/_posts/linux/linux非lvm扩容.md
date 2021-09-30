---
title: linux 非lvm分区扩容
date: 2021-09-17 11:24
categories:
- linux
tags:
- linux
---
	
	
摘要: linux 非lvm分区扩容
<!-- more -->

## 背景：
硬盘从200G扩容到500G

## 操作步骤：
安装growpart 工具
```
yum install cloud-utils-growpart 
```


扩容/data目录步骤如下。

一、查看vdc云盘大小为200G，目录/data为20G
```
# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
vda    253:0    0  100G  0 disk 
└─vda1 253:1    0  100G  0 part /
vdb    253:16   0    8G  0 disk [SWAP]
vdc    253:32   0  500G  0 disk 
└─vdc1 253:33   0  200G  0 part /data
```

二、使用growpart工具扩容分区vdc1
```
# growpart /dev/vdc 1
CHANGED: partition=1 start=2048 old: size=419428352 end=419430400 new: size=1048573919 end=1048575967
```

三、扩容文件系统
```
# xfs_growfs /dev/vdc1

meta-data=/dev/vdc1              isize=512    agcount=4, agsize=13107136 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0 spinodes=0
data     =                       bsize=4096   blocks=52428544, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal               bsize=4096   blocks=25599, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 52428544 to 131071739

```

查看扩容结果
```
# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
vda    253:0    0  100G  0 disk 
└─vda1 253:1    0  100G  0 part /
vdb    253:16   0    8G  0 disk [SWAP]
vdc    253:32   0  500G  0 disk 
└─vdc1 253:33   0  500G  0 part /data
```
...
```
# df -h
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        7.8G     0  7.8G   0% /dev
tmpfs           7.8G     0  7.8G   0% /dev/shm
tmpfs           7.8G   17M  7.8G   1% /run
tmpfs           7.8G     0  7.8G   0% /sys/fs/cgroup
/dev/vda1        99G   79G   15G  85% /
/dev/vdc1       500G  186G  315G  38% /data
tmpfs           1.6G     0  1.6G   0% /run/user/1002
```


## 总结：
1、先扩容云硬盘大小

2、growpart工具扩容分区

3、xfs_growfs（用于XFS文件系统）或者resize2fs命令（用户ext2/ext3/ext4）扩容文件系统