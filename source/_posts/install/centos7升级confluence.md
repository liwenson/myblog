---
title: centos7升级confluence
date: 2021-03-20 16:47
categories:
- centos7
tags:
- confluence
---
  
  
摘要: cenfluence6.12 升级cenfluence7.4.8
<!-- more -->


## 升级流程

### 备份数据
#### 官方备份
```
点击 一般设置 --> 备份与还原  --> 备份
```
#### 手动备份
```
1，备份数据源。默认路径为：/var/atlassian/application-data/confluence/confluence.cfg.xml

2，备份附件。默认路径为：/var/atlassian/application-data/confluence/attachments
```

#### 备份破解文件
```
mv /opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.4.1.jar ~/atlassian-extras-2.4.jar
```


## 部署最新版本

### 获取新的版本
[官方下载地址](https://www.atlassian.com/software/confluence/download)

### 执行
将新版安装包放在 `/opt` 目录下
```
chmod +x atlassian-confluence-7.4.8-x64.bin
./atlassian-confluence-7.4.8-x64.bin
```

```
......
Starting Installer ...

This will install Confluence 7.4.8 on your computer.
OK [o, Enter], Cancel [c]
o        # 回车 或按 o
Click Next to continue, or Cancel to exit Setup.

Choose the appropriate installation or upgrade option.
Please choose one of the following:
Express Install (uses default settings) [1], 
Custom Install (recommended for advanced users) [2], 
Upgrade an existing Confluence installation [3, Enter]
3       # 选择3 表示更新
Existing installation directory:
[/opt/atlassian/confluence]


Back Up Confluence Home
The upgrade process will automatically back up your Confluence Installation
Directory. You can also choose to back up your existing Confluence Home
Directory. Both directories are backed up as zip archive files in their
respective parent directory locations.

We strongly recommend choosing this option in the unlikely event that you
experience problems with the upgrade and may require these backups to
restore your existing Confluence installation.

If you have many attachments in your Confluence Home Directory, the zip
archive of this directory may consume a significant amount of disk space.
Back up Confluence home ?
Yes [y, Enter], No [n]
y     # 询问是否需要备份

Checking for local modifications.

List of modifications made within Confluence directories.

The following provides a list of file modifications within the confluence
directory.

Modified files:
	confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.4.1.jar
Removed files:
	(none)
Added files:
	confluence/WEB-INF/classes/log4j-diagnostic.properties
	confluence/WEB-INF/lib/mysql-connector-java-5.1.46-bin.jar

[Enter]


Checking if your instance of Confluence is running

Upgrade Check List
Back up your external database
We strongly recommend you back up your Confluence database if you have not
already done so.

Please refer to the following URL for back up guidelines:
https://docs.atlassian.com/confluence/docs-74/Production+Backup+Strategy

Check plugin compatibility
Check that your non-bundled plugins are compatible with Confluence 7.4.8.

Access the plugin manager through the following URL:
http://localhost:8090/plugins/servlet/upm#compatibility

For more information see our documentation at the following URL:
https://docs.atlassian.com/confluence/docs-74/Installing+and+Configuring+Plugins+using+the+Universal+Plugin+Manager


Please ensure you have read the above checklist before upgrading.
Your existing Confluence installation is about to be upgraded!

The upgrade process will shut down your existing Confluence installation to complete the upgrade.

Do you want to proceed?
Upgrade [u, Enter], Exit [e]
u               #  展示改变的文件，询问是否升级

Your instance of Confluence is currently being upgraded.
Shutting down Confluence...
Checking if Confluence has been shutdown...
Backing up the Confluence installation directory
                                                                           
Backing up the Confluence home directory
                                                                           
Deleting the previous Confluence installation directory...

Extracting files ...
                                                                           

Please wait a few moments while we configure Confluence.

Installation of Confluence 7.4.8 is complete
Start Confluence now?
Yes [y, Enter], No [n]
y          # 部署完成 ，是否启动

Please wait a few moments while Confluence starts up.
Launching Confluence ...

Installation of Confluence 7.4.8 is complete
Your installation of Confluence 7.4.8 is now ready and can be accessed via
your browser.
Custom modifications
Your previous Confluence installation contains customisations that must be
manually transferred. Refer to our documentation more information:
https://docs.atlassian.com/confluence/docs-74/Upgrading+Confluence#UpgradingConfluence-custommodifications
Confluence 7.4.8 can be accessed at http://localhost:8090

Confluence 7.4.8 may take several minutes to load on first start up.
Finishing installation ...

```


### 访问
```
ip:8090
```

## 界面报错处理
报错一:  更新之后破解文件失效了, 将备份的破解文件替换回去
```
LicenseException:Failed to verify the license.
```
将备份的破解文件替换回去
```
mv ~/atlassian-extras-2.4.jar /opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.4.1.jar
```
重启服务

报错二: 
```
MySQL session isolation level 'REPEATABLE-READ' is no longer supported. Session isolation level must be 'READ-COMMITTED'. See http://confluence.atlassian.com/x/GAtmDg
```
修改 mysql 默认事务隔离级别
需要修改/etc/my.cnf

在[mysqld]下增加一行
```
transaction-isolation=READ-COMMITTED
```

重启mysqld
重启confluence


## 升级完成



