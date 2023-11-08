---
title: jenkins更新插件镜像
date: 2021-03-24 16:37
categories:
- jenkins
tags:
- jenkins
---
  
  
摘要: jenkins更新插件镜像地址
<!-- more -->


## 备份

```
cd /var/lib/jenkins/updates
cp default.json default.json.back
```

## 替换域名
```
sed -i 's#https://updates.jenkins.io/download#https://mirrors.tuna.tsinghua.edu.cn/jenkins#g' default.json && sed -i 's#http://www.google.com#https://www.baidu.com#g' default.json
```

## 重启服务
```
systemctl restart jenkins
```