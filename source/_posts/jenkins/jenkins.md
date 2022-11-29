---
title: jenkins 常见问题
date: 2019-12-18 10:00:00
categories: 
- jenkins
tags:
- jenkins
---



## jenkins 工作目录修改

```
/etc/sysconfig/jenkins 
修改 JENKINS_HOME
```

**旧**:

```
系统管理→系统设置→主目录（的右边问号下面）→高级（是不是忽略了啊\(^o^)/~）→工作空间根目录
```

点开后面的问号可以看见3个参数（配置路径需要的）：

1. - `${JENKINS_HOME}` — **Jenkins** home directory.#JENKINS_HOME这个参数不用说了
   - `${ITEM_ROOTDIR}` — Root directory of a job for which the default workspace is allocated.#ITEM_ROOTDIR：默认的工作空间目录。完整的路径就是JENKINS_HOME/jobs/xxxx/workspace
   - `${ITEM_FULL_NAME}` — '/'-separated job name, like "foo/bar".#ITEM_FULL_NAME：job的名称，这个就是我们需要的。

 我们只需要把workspace目录赶出JENKINS_HOME目录就行了。上配置：

```
workspace：/home/froad/workspace/${ITEM_FULL_NAME}#前面的目录随便你改，只需要在最后带上${ITEM_FULL_NAME}JENKINS_HOME：/home/froad/.jenkins#给你们对比着看
#好了，这下.svn目录不打架了。我也不用头疼了。
```

删除已经存在的workspace目录

```
find . -type d -name"workspace"|xargs rm -rf#看见find后面的那个点了么，改成你的路径就行了
```

**新**:



```
在  config.xml   文件内，查找 workspaceDir 关键字，将你的自定义 工作空间根目录 地址替换默认的地址
```

```
  <workspaceDir>/opt/jenkins/workspace/${ITEM_FULL_NAME}</workspaceDir>
```

重启jenkins

## 删除构建历史

```
//项目名称
def jobName = "be-ztocwst-zop-sftpglj"
//删除小于等于64的构建历史
def maxNumber = 64

Jenkins.instance.getItemByFullName(jobName).builds.findAll {
  it.number <= maxNumber
}.each {
  it.delete()
}

```

## 重置build号

```
// 重置build号
item = Jenkins.instance.getItemByFullName("be-ztocwst-zop-sftpglj")
item.builds.each() { build ->
  build.delete()
}
item.updateNextBuildNumber(1)

```

## 忘记Jenkins管理员密码的解决办法

### 一、admin密码未更改情况

1.进入\Jenkins\secrets目录，打开initialAdminPassword文件，复制密码；

2.访问Jenkins页面，输入管理员admin，及刚才的密码；

3.进入后可更改其他管理员密码；

### 二、admin密码更改忘记情况

1.删除Jenkins目录下config.xml文件中下面代码，并保存文件。

```xml
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy">
    <denyAnonymousReadAccess>true</denyAnonymousReadAccess>
  </authorizationStrategy>
  <securityRealm class="hudson.security.HudsonPrivateSecurityRealm">
    <disableSignup>true</disableSignup>
    <enableCaptcha>false</enableCaptcha>
  </securityRealm>
```

2.重启Jenkins服务；

3.进入首页>“系统管理”>“Configure Global Security”；

4.勾选“启用安全”；

5.点选“Jenkins专有用户数据库”，并点击“保存”；

6.重新点击首页>“系统管理”,发现此时出现“管理用户”；

7.点击进入展示“用户列表”；

8.点击右侧进入修改密码页面，修改后即可重新登录。
