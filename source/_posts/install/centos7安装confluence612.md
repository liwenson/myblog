---
title: centos7安装confluence 6.12
date: 2021-03-15 16:16
categories:
- centos7
tags:
- confluence
---
  
  
摘要:centos7安装confluence 6.12 
<!-- more -->


## 环境
```
centos 7.7
JDK 1.8
mysql 5.7(配置文件my.cnf中设置了UTF-8)
```

## 数据库初始化
```
Mysql> SET GLOBAL tx_isolation='READ-COMMITTED';
Mysql> CREATE DATABASE confluence CHARACTER SET utf8 COLLATE utf8_bin;
Mysql> grant all on confluence.* to confluence@"%" identified by 'confluence';
Mysql> grant all on confluence.* to confluence@"%";
Mysql> FLUSH PRIVILEGES;
```

## 获取confluence
```
wget https://product-downloads.atlassian.com/software/confluence/downloads/atlassian-confluence-6.12.0-x64.bin
chmod +x atlassian-confluence-6.12-x64.bin
```

## 安装
```
./atlassian-confluence-6.12.0-x64.bin
```

```
Unpacking JRE ...
Starting Installer ...

This will install Confluence 6.12.0 on your computer.
OK [o, Enter], Cancel [c]
o       # 回车或按 o
Click Next to continue, or Cancel to exit Setup.

Choose the appropriate installation or upgrade option.
Please choose one of the following:
Express Install (uses default settings) [1], 
Custom Install (recommended for advanced users) [2, Enter], 
Upgrade an existing Confluence installation [3]
1     # 选 1

See where Confluence will be installed and the settings that will be used.
Installation Directory: /opt/atlassian/confluence 
Home Directory: /var/atlassian/application-data/confluence 
HTTP Port: 8090 
RMI Port: 8000 
Install as service: Yes 
Install [i, Enter], Exit [e]
i    # 回车 或按 i

Extracting files ...


Please wait a few moments while we configure Confluence.

Installation of Confluence 6.12.0 is complete
Start Confluence now?
Yes [y, Enter], No [n]
y    # 回车 或按 y

Please wait a few moments while Confluence starts up.
Launching Confluence ...

Installation of Confluence 6.12.0 is complete
Your installation of Confluence 6.12.0 is now ready and can be accessed via
your browser.
Confluence 6.12.0 can be accessed at http://localhost:8090
Finishing installation ...
```

## confluence控制
```
cd /opt/atlassian/confluence/bin/
./stop-confluence.sh       # 停止
./start-confluence.sh      # 启动
```

## 破解

停止
```
cd /opt/atlassian/confluence/bin/
./stop-confluence.sh       # 停止
```
替换文件 和上传 mysql-jdbc
```

```

<hr>

- 1： /opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.4.1.jar文件到本地
- 2：本地重命名为atlassian-extras-2.4.jar
- 3：打开破解工具confluence_keygen.jar（本地需先安装java）
- 4：选择.patch!找atlassian-extras-2.4.jar打开
- 5：可以看到atlassian-extras-2.4.jar和atlassian-extras-2.4.bak两个文件，这里atlassian-extras-2.4.jar已经是破解好的了，将atlassian-extras-2.4.jar名字改回来atlassian-extras-decoder-v2-3.4.1.jar
- 6：将atlassian-extras-decoder-v2-3.4.1.jar上传到服务器原目录
-----
## web配置
```
浏览器访问http://localhost:8090

1、右上角选择中文语言
   选择 Production Installation
2、下一步
3、授权码
复制服务器ID到confluence_keygen.jar 中的server ID，点击.gen!,将生成的key粘贴到浏览器
4、选择我的数据库
5、选择mysql,填入mysql连接信息
6、选择空白站点
7、选择 在confluence 中管理用户和组
8、填写管理员账号信息

```



