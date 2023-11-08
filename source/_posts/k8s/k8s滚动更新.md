---
title: k8s滚动更新
date: 2023-04-10 15:48
categories:
- k8s
tags:
- k8s
---
  
  
摘要: desc
<!-- more -->


在传统的应用升级时，通常采用的方式是先停止服务，然后升级部署，最后将新应用启动。这个过程面临一个问题，就是在某段时间内，服务是不可用的，对于用户来说是非常不友好的。而kubernetes滚动更新，将避免这种情况的发生。

对于Kubernetes集群来说，一个service可能有多个pod。滚动升级（RollingUpdate）就是指每次更新部分Pod，直至所有的Pod更新完成，达到平滑升级的效果，而不是在同一时刻将该Service下面的所有Pod停止。


## 镜像准备

```
dockerproxy.com/library/nginx:1.19
dockerproxy.com/library/nginx:1.23
```

## 更新策略

```
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1

```
字段含义

    type：设置更新策略。有两个可选项：recreate和RollingUpdate（默认）。Recreate表示全部重新创建，RollingUpdate表示滚动更新。
    maxSurge：升级过程中最多可以比原先设置多出的POD数量，可以是数字，也可以是比例。例如：maxSurage=1，replicas=5,则表示升级过程中最多会有5+1个POD。
    升级过程中最多允许有多少个POD处于不可用状态。maxUnavailable =1 表示升级过程中最多会有一个pod可以处于无法服务的状态，在这里就是至少要有5-1个pod正常。 

说明：maxSurge和maxUnavaible在更新策略为RollingUpdate时才需要设置。


## 例子

更新nginx版本

```
# vim deployment.yaml

---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx-deploy
  name: nginx-deploy
spec:
  replicas: 5  # 副本数量
  revisionHistoryLimit: 10  # 保留的版本数
  minReadySeconds: 5  # pod 启动多少秒后，提供服务
  strategy:
    type: RollingUpdate    # 滚动更新
    rollingUpdate:
      maxSurge: 1      # 更新期间存在的总 Pod 副本数最多可超出期望值 spec.replicas 的个数，默认是 1
      maxUnavailable: 1    #  升级过程中最多允许多少个pod处于不可用状态
  selector:
    matchLabels:
      app: nginx-deploy
  template:
    metadata:
      labels:
        app: nginx-deploy
    spec:
      restartPolicy: Always
      containers:
        - name: mynginx
          image: nginx:1.19
          imagePullPolicy: IfNotPresent

```

创建

```
kubectl apply -f deployment.yaml
deployment.apps/nginx-deploy created
```


使用nginx:1.19版本启动了5个pod。

```
kubectl get pod

NAME                            READY   STATUS    RESTARTS   AGE
nginx-deploy-5dfdf9fbdd-bgq6l   1/1     Running   0          31m
nginx-deploy-5dfdf9fbdd-gkbnq   1/1     Running   0          31m
nginx-deploy-5dfdf9fbdd-hkxhb   1/1     Running   0          31m
nginx-deploy-5dfdf9fbdd-kc6cx   1/1     Running   0          31m
nginx-deploy-5dfdf9fbdd-w8z86   1/1     Running   0          31m

```


进行升级，使用nginx:1.23。我这里使用命令行

```
kubectl set image deployment/nginx-deploy mynginx=nginx:1.23 --record
```

yaml 文件更新,修改yaml内容后执行更新

```
kubectl apply -f deployment.yaml --record
```

通过命令kubectl get pod -w我们可以看到整个清晰地过程，即创建一个pod，再删除一个pod，直至所有的pod被更新完成

```
kubectl get pod -w
```

查看更新过程

```
kubectl describe deployment nginx-deploy
```

查看更新之后的yaml

```
kubectl get deploy nginx-deploy -o yaml


apiVersion: apps/v1
kind: Deployment
...
spec:
  containers:
  - image: nginx:1.23
    imagePullPolicy: IfNotPresent
    name: mynginx
...

```

可以发现nginx已经被更新为1.23版本，更新成功。


## 版本回退

有版本升级，就会有对应的版本回退。我们可以通过以下命令来完成版本回退。

```
# 历史记录
kubectl rollout history deployment/nginx-deploy


deployment.apps/nginx-deploy
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl set image deployment/nginx-deploy mynginx=nginx:1.23 --record=true


```

VERSION=1表示最初始的版本。VERSION=2表示一次升级的版本，依次类推...

查看某个版本历史详情

```
kubectl rollout history deployment/nginx-deploy --revision=1
```

 回滚(回到上次)

```
kubectl rollout undo deployment/nginx-deploy
```

 回滚(回到指定版本)

```
kubectl rollout undo deployment/nginx-deploy --to-revision=2
```


## 注意

### 更新策略 

我们这里使用的是滚动更新RollingUpdate。如何使用Recreate，会和传统的升级方法一样，先停掉所有的pod，然后重建pod。

### 参数设置 

当 maxSurge 设置为0的时候，maxUnavailable不能设置为0。maxSurge=0时先删除后启动，maxSurge!=0时先启动后删除。



