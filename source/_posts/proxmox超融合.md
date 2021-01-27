---
title: proxmox 超融合
date: 2020-5-11 14:00:00
categories: 
- linux
tags:
- proxmox
---



**安装前准备**

不使用磁盘控制器，不要做raid



### 安装部署

略



**刪除內建的LVM thin**

LVM 有两种，分为 Thin 和 非Thin， 而 pve內建的 local-lvm 的格式是 LVM-Thin ，在使用上有好处也有坏处:

1) 好处:用来建vm or ct 可以有 snapshot(快照)的功能，而且可以超额分配硬碟空间(当然是有代价的)

2) 坏处:这个分割区你无法直接放档案进去，等于这个分割区只能給 vm or ct 专用了

若你不想使用 LVM-Thin 想把它移掉，只当一般的 LVM 使用，LVM 相对于 LVM-thin 的优缺点如下:

1) 优点:你可以直接放档案进去

2) 缺点:vm or ct 沒有快照功能，不能超额分配硬碟空间

按下面的方法转换成一般的LVM 来使用

注意:底下的操作会刪掉你 local-lvm 里的所有资料，请确定你 local-lvm 里沒有要保留的资料





```bash
apt update
```