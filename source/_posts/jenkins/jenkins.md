---
title: jenkins 常见问题
date: 2019-12-18 10:00:00
categories: 
- jenkins
tags:
- jenkins
---



### jenkins 工作目录修改

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