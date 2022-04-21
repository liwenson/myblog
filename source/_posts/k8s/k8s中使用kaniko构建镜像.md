---
title: k8s中使用kaniko构建镜像
date: 2022-04-15 10:10
categories:
- k8s
tags:
- kaniko
---
  
  
摘要: k8s中使用kaniko构建镜像
<!-- more -->

## 创建ns

把所有与kaniko相关的全部放在kaniko这个ns下。

```bash
kubectl create ns kaniko
```

## 获取kaniko镜像

gcr上的镜像不好拉，在dockerhub已经有人上传过了。

可以在自己的镜像仓库生成这些镜像的(<https://blog.csdn.net/u010918487/article/details/108084651>)

```bash
// latest
docker pull xkfen/kaniko:v1.0.0
 
// debug
docker pull xkfen/kaniko:debug
 
// warmer
docker pull xkfen/kaniko:warmer
```

## 私有镜像仓库需要账号密码

### 创建命令

格式

```bash
kubectl create secret docker-registry regcred \
  --docker-server=<你的镜像仓库服务器> \
  --docker-username=<你的用户名> \
  --docker-password=<你的密码> \
  --docker-email=<你的邮箱地址>
```

```bash
kubectl create secret docker-registry harbor-regsecret-secret \
  --docker-server=http://harbor.test.com \
  --docker-username=admin \
  --docker-password=a123456 \
  -n kaniko
```

```bash
kubectl create secret generic jenkins-k8s-cfg -n jenkins-ns --from-file=/root/.kube/config
```

### 查看刚刚生成的secret

```bash
kubectl get secret harbor-regsecret-secret -n kaniko -o yaml

apiVersion: v1
data:
  .dockerconfigjson: eyJhdXRocyI6eyJodHRwOi8vcmVnLnp0b3ljLmNvbSI6eyJ1c2VybmFtZSI6ImFkbWluIiwicGFzc3dvcmQiOiJ6dHljMTIzNCIsImF1dGgiOiJZV1J0YVc0NmVuUjVZekV5TXpRPSJ9fX0=
kind: Secret
metadata:
  creationTimestamp: "2022-04-15T02:25:34Z"
  name: harbor-regsecret-secret
  namespace: default
  resourceVersion: "535300"
  selfLink: /api/v1/namespaces/default/secrets/harbor-regsecret-secret
  uid: a144ea36-2658-42ee-bde4-ec5d0ff30807
type: kubernetes.io/dockerconfigjson
```

私有镜像仓库不需要账号密码的，就不用创建这个secret。

在后面的pod.yaml中也不需要挂载kaniko-secret。

如果私有仓库地址不是https的，是http的，那么就要设置insecure参数为true，这个参数默认为false的。设置为true代表使用http把镜像push到镜像仓库。(Push to insecure registry using plain HTTP)

## hostpath 方式

Dockerfile

```docker
FROM ubuntu
ENTRYPOINT ["/bin/bash", "-c", "echo hello"]
```

pod.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kaniko
spec:
  nodeName: k8s-01
  #nodeSelector:
  #  kubernetes.io/hostname: prod-l27-4-23
  containers:
  - name: kaniko
    image: reg.ztoyc.com/library/kaniko-executor@sha256:b0ca0b4fb16822e55ea1250c54c73c7c4248282908065422ededa49fa400436a
    args: ["--verbosity=trace",
           "--log-format=color",
           "--dockerfile=Dockerfile",
           "--context=dir:///data/kaniko",
           "--destination=reg.ztoyc.com/library/ayena:test",
           "--skip-tls-verify=true",
           "--insecure=true",
           "--insecure-pull" ]
    volumeMounts:
      - name: kaniko-secret
        mountPath: /kaniko/.docker 
      - name: context-data
        mountPath: /data/kaniko
  restartPolicy: Never
  volumes:
    - name: context-data
      hostPath:
        path: /data/kaniko
        type: Directory
    - name: kaniko-secret
      secret:
        secretName: harbor-regsecret-secret
        items:
          - key: .dockerconfigjson
            path: config.json
```

## docker 方式

```bash
docker run --name kaniko \
    -v /root/.docker/:/kaniko/.docker \
    -v `pwd`:/workspace \
    reg.ztoyc.com/library/kaniko-executor:v1.7.0-debug \
    --dockerfile /workspace/Dockerfile \
    --destination reg.ztoyc.com/library/ayena:test02 \
    --context dir:///workspace/ \
    --skip-tls-verify \
    --insecure=true \
    --insecure-pull
```
