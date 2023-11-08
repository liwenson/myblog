---
title: k8s 金丝雀更新
date: 2023-04-10 16:04
categories:
- k8s
tags:
- k8s
---
  
  
摘要: desc
<!-- more -->


## 局限性

按照 Kubernetes 默认支持的这种方式进行金丝雀发布，有一定的局限性：

    不能根据用户注册时间、地区等请求中的内容属性进行流量分配
    同一个用户如果多次调用该 Service，有可能第一次请求到了旧版本的 Pod，第二次请求到了新版本的 Pod

TIP

在 Kubernetes 中不能解决上述局限性的原因是：Kubernetes Service 只在 TCP 层面解决负载均衡的问题，并不对请求响应的消息内容做任何解析和识别。如果想要更完善地实现金丝雀发布，可以考虑如下三种选择：

    业务代码编码实现
    Spring Cloud 灰度发布
    Istio 灰度发布
  

## 镜像准备

```
dockerproxy.com/library/nginx:1.19
dockerproxy.com/library/nginx:1.23
```


## 部署第一个版本

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: dockerproxy.com/library/nginx:1.19
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  labels:
    app: nginx
spec:
  selector:
    app: nginx
  ports:
  - name: nginx-port
    protocol: TCP
    port: 80
    nodePort: 32600
    targetPort: 80
  type: NodePort
```


此时想要发布新的版本 nginx 1.23，可以创建第二个 Deployment：



```
vim  deployment-canary.yaml


apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment-canary
  labels:
    app: nginx
    track: canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
      track: canary
  template:
    metadata:
      labels:
        app: nginx
        track: canary
    spec:
      containers:
      - name: nginx
        image: dockerproxy.com/library/nginx:1.23
```

    因为 Service 的LabelSelector 是 app: nginx，由 nginx-deployment 和 nginx-deployment-canary 创建的 Pod 都带有标签 app: nginx，所以，Service 的流量将会在两个 release 之间分配
    在新旧版本之间，流量分配的比例为两个版本副本数的比例，此处为 1:3

当您确定新的版本没有问题之后，可以将 nginx-deployment 的镜像标签修改为新版本的镜像标签，并在完成对 nginx-deployment 的滚动更新之后，删除 nginx-deployment-canary 这个 Deployment