---
title: mongodb 安装和用户管理
date: 2020-09-21 12:45
categories:
- mongodb
tags:
- mongodb
- auth
---


### 安装mongodb3.2

下载mongodb

```
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.2.3.tgz
```

```
tar xf mongodb-linux-x86_64-rhel62-3.2.3.tgz
mv mongodb-linux-x86_64-rhel62-3.2.3 mongodb
cd mongodb
mkdir data logs conf
```



配置文件

```
vim conf/mongod.conf

systemLog:
  destination: file
  path: /opt/mongodb-27017/logs/mongod.log
  logAppend: true
processManagement:
  fork: true
  pidFilePath: "/opt/mongodb-27017/data/mongod.pid"
net:
  port: 27017
  http:
    enabled: true
storage:
  dbPath: "/opt/mongodb-27017/data"
  engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: zlib
    indexConfig:
      prefixCompression: true
  journal:
    enabled: true
  directoryPerDB: true
security:
  authorization: enabled      # 开启关闭验证
```

`mongo3.x以后的版本配置文件都是yaml格式的，官方关于mongo配置文件相关选项说明，https://docs.mongodb.org/manual/reference/configuration-options/#configuration-file`



启动mongo

```
/opt/mongodb-27017/bin/mongod -f /opt/mongodb-27017/conf/mongod.conf
```



```
ps -ef | grep mongo

root      4801     1  1 15:25 ?        00:00:22 /opt/mongodb-27017/bin/mongod -f /opt/mongodb-27017/conf/mongod.conf
root      4849     1  1 15:29 ?        00:00:18 /opt/mongodb-27018/bin/mongod -f /opt/mongodb-27018/conf/mongod.conf
```





### monodb 用户管理



角色

Read：    允许用户读取指定数据库

readWrite：   允许用户读写指定数据库

dbAdmin：    允许用户在指定数据库中执行管理函数，如索引创建、删除，查看统计或访问system.profile

userAdmin：  允许用户向system.users集合写入，可以找指定数据库里创建、删除和管理用户

clusterAdmin：  只在admin数据库中可用，赋予用户所有分片和复制集相关函数的管理权限。

readAnyDatabase：   只在admin数据库中可用，赋予用户所有数据库的读权限

readWriteAnyDatabase：   只在admin数据库中可用，赋予用户所有数据库的读写权限

userAdminAnyDatabase：   只在admin数据库中可用，赋予用户所有数据库的userAdmin权限

dbAdminAnyDatabase：   只在admin数据库中可用，赋予用户所有数据库的dbAdmin权限。

root：   只在admin数据库中可用。超级账号，超级权限

  1. 数据库用户角色:    read、readWrite；
  2. 数据库管理角色:    dbAdmin、dbOwner、userAdmin;
  3. 集群管理角色:      clusterAdmin、clusterManager、4. clusterMonitor、hostManage；
  4. 备份恢复角色:      backup、restore；
  5. 所有数据库角色:      readAnyDatabase、readWriteAnyDatabase、userAdminAnyDatabase、dbAdminAnyDatabase
  6. 超级用户角色:      root
  7. 内部角色:   __system



`注意： 用户在哪个库创建，就要在哪个库auth认证，并在mongo登录时也要先连接认证库`



### 创建admin 超级管理员用户

```
use admin
db.createUser(
  { user: "admin",  
    customData：{description:"superuser"},
    pwd: "admin",  
    roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]  
  }  
) 
```

超级用户的role有两种，userAdmin或者userAdminAnyDatabase(比前一种多加了对所有数据库的访问,仅仅是访问而已)。



### 创建一个不受访问限制的超级用户

```
use admin
db.createUser(
    {
        user:"root",
        pwd:"pwd",
        roles:["root"]
    }
)
```

### 创建一个业务数据库管理员用户

```
use admin
db.createUser({
    user:"user001",
    pwd:"123456",
    customData:{
        name:'jim',
        email:'jim@qq.com',
        age:18,
    },
    roles:[
        {role:"readWrite",db:"db001"},
        {role:"readWrite",db:"db002"},
        'read'   // 对其他数据库有只读权限，对db001、db002是读写权限
    ]
})
```

### 查看创建的用户

```
show users    或     db.system.users.find()     或    db.runCommand({usersInfo:"userName"})
```

### 修改密码

```
use admin
db.changeUserPassword("username", "xxx")
```

### 修改密码和用户信息

```
db.runCommand(
    {
        updateUser:"username",
        pwd:"xxx",
        customData:{title:"xxx"}
    }
)
```

### 删除数据库用户

```
use admin
db.dropUser('user001')
```

### 创建其他数据管理员

```
// 登录管理员用户
use admin
db.auth('admin','admin')
// 切换至db001数据库
use db001
// ... 増查改删该数据库专有用户
```

```
use admin
db.createUser({user:'superadmin',pwd:'123456', roles:[{role:'root', db:'admin'}]})     ---创建超级管理员用户
 
db.createUser({user:'useradmin',pwd:'123456', roles:[{role:'userAdminAnyDatabase', db:'admin'}]})     ---创建用户管理员账户（能查询其他库集合，但不能查询集合内容）
 
db.createUser({user:'admin',pwd:'123456', roles:[{role:'readWriteAnyDatabase', db:'admin'}]})     ---创建访问任意库读写的账户
 
db.createUser({user:'user1',pwd:'user1',roles:[{role:'readWrite',db:'test'}]})     ---创建只对test库有读写权限的用户
 
db.createUser({user:"bkuser2",pwd:"Bkuser2",roles:[{role:"backup",db:"admin"}]})     ---创建用于备份时的用户，如若是恢复权限，则将backup换为restore即可
--- 注：新建backup账户时，roles里面的db必须是admin，要不然会报错
```




