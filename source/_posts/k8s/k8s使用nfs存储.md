---
title: k8s中使用nfs作为存储
date: 2022-03-31 12:04
categories:
- k8s
tags:
- nfs
---
  
  
摘要: k8s 中使用nfs
<!-- more -->

## k8s中的存储方式

### k8s的emptydir和hostpath、configmap以及secret的机制和用途

```txt

1、Emptydir
EmptyDir是一个空目录，他的生命周期和所属的 Pod 是完全一致的，pod删掉目录消失

2、Hostpath
Hostpath会把宿主机上的指定卷加载到容器之中，如果 Pod 发生跨主机的重建，其内容就难保证了

3、Configmap
ConfigMap跟Secrets类似，但是ConfigMap可以更方便的处理不包含敏感信息的字符串。
当ConfigMap以数据卷的形式挂载进Pod的时，这时更新ConfigMap（或删掉重建ConfigMap），Pod内挂载的配置信息会热更新。这时可以增加一些监测配置文件变更的脚本，然后reload对应服务

4、Secret
Secret来处理敏感数据，比如密码、Token和密钥，相比于直接将敏感数据配置在Pod的定义或者镜像中，Secret提供了更加安全的机制（Base64加密），防止数据泄露。Secret的创建是独立于Pod的，以数据卷的形式挂载到Pod中，Secret的数据将以文件的形式保存，容器通过读取文件可以获取需要的数据

```

### k8s的持久化存储方案，目前k8s支持的存储方案主要如下

```txt
分布式文件系统： NFS/GlusterFS/CephFS
公有云存储方案： AWS/GCE/Auzre
```

### 什么是PV、PVC、StorageClass

```txt
PV
PersistentVolume（持久化卷），是对底层的共享存储的一种抽象，主要是定义一个磁盘的大小

PVC
PersistentVolumeClaim（持久化卷声明），PVC 是用户存储的一种声明，PVC 和 Pod 比较类似，Pod 消耗的是节点，PVC 消耗的是 PV 资源


StorageClass
PVC 请求到一定的存储空间也很有可能不足以满足应用对于存储设备的各种需求，而且不同的应用程序对于存储性能的要求可能也不尽相同，比如读写速度、并发性能等，为了解决这一问题，Kubernetes 又为我们引入了一个新的资源对象：StorageClass，通过 StorageClass 的定义，用户根据 StorageClass 的描述就可以非常直观的知道各种存储资源的具体特性了，这样就可以根据应用的特性去申请合适的存储资源了
```

### AccessModes（访问模式）

AccessModes 是用来对 PV 进行访问模式的设置，用于描述用户应用对存储资源的访问权限，访问权限包括下面几种方式：

```txt
ReadWriteOnce（RWO）: 读写权限，但是只能被单个节点挂载
ReadOnlyMany（ROX）: 只读权限，可以被多个节点挂载
ReadWriteMany（RWX）: 读写权限，可以被多个节点挂载
```

### ReclaimPolicy（回收策略）

我这里指定的 PV 的回收策略为 Recycle，目前 PV 支持的策略有三种

```txt
Retain（保留）- 保留数据，需要管理员手工清理数据
Recycle（回收）- 清除 PV 中的数据，效果相当于执行 rm -rf /thevoluem/*
Delete（删除）- 与 PV 相连的后端存储完成 volume 的删除操作，当然这常见于云服务商的存储服务，比如 ASW EBS。
```

不过需要注意的是，目前只有 NFS 和 HostPath 两种类型支持回收策略。当然一般来说还是设置为 Retain 这种策略保险一点。

### 状态

一个 PV 的生命周期中，可能会处于4中不同的阶段

```txt
Available（可用）：表示可用状态，还未被任何 PVC 绑定
Bound（已绑定）：表示 PVC 已经被 PVC 绑定
Released（已释放）：PVC 被删除，但是资源还未被集群重新声明
Failed（失败）： 表示该 PV 的自动回收失败
```

## 部署nfs

略

k8s node需要安装nfs工具

```bash
yum install nfs-utils -y
```

## 部署NFS-StorageClass

NFS-StorageClass 是不支持扩容的

下载需要的yaml文件

```bash
for file in class.yaml deployment.yaml rbac.yaml test-claim.yaml ; do wget https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/$file ; done

```

下载失败可以复制下面的文本

### 命名空间

```bash
kubectl create namespace nfs-provisioner
```

或

```bash
vim namespace.yaml
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nfs-provisioner
  labels:
    app: nfs-provisioner
```

### 创建account及相关权限

```bash
vim nfs-rbac.yaml
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: nfs-provisioner
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: nfs-provisioner
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: nfs-provisioner
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: nfs-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: nfs-provisioner
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
```

### StorageClass

```bash
vim nfs-storageclass.yaml
```

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: managed-nfs-storage
provisioner: fuseim.pri/ifs   # 这里的名称要和provisioner配置文件中的环境变量PROVISIONER_NAME保持一致
reclaimPolicy: Retain     # 默认为delete
parameters:
  archiveOnDelete: "false"   # false表示pv被删除时，在nfs下面对应的文件夹也会被删除,true正相反
```

### 创建NFS provisioner

```bash
vim nfs-deployment.yaml
```

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nfs-provisioner
  namespace: nfs-provisioner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-provisioner
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-provisioner
    spec:
      serviceAccount: nfs-client-provisioner
      containers:
        - name: nfs-provisioner
          # image: registry.cn-hangzhou.aliyuncs.com/open-ali/nfs-client-provisioner
          image: registry.cn-beijing.aliyuncs.com/mydlq/nfs-subdir-external-provisioner:v4.0.0
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: fuseim.pri/ifs        ## 这里的供应者名称必须和class.yaml中的provisioner的名称一致，否则部署不成功
            - name: NFS_SERVER
              value: 10.200.92.60
            - name: NFS_PATH
              value: /home/data/nfs/k8s
      volumes:
        - name: nfs-client-root
          nfs:
            server: 10.200.92.60
            path: /home/data/nfs/k8s
```

### 创建PVC

```bash
vim nfs-pvc.yaml
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: managed-nfs-storage
  resources:
    requests:
      storage: 1Gi
```

```bash
kubectl apply -f pvc-nfs.yaml

kubectl get pvc


NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nfs   Bound    pvc-7461b40b-f52e-4bf6-9d73-40432b77f108   1Gi        RWO            nfs            1s

```

```yaml
kind: Pod
apiVersion: v1
metadata:
 name: test-pod
spec:
 containers:
 - name: test-pod
   image: busybox:1.24
   command:
     - "/bin/sh"
   args:
     - "-c"
     - "touch /mnt/SUCCESS && exit 0 || exit 1"   #创建一个SUCCESS文件后退出
   volumeMounts:
     - name: pvc-nfs
       mountPath: "/mnt"
 restartPolicy: "Never"
 volumes:
   - name: pvc-nfs
     persistentVolumeClaim:
       claimName: pvc-nfs #与PVC名称保持一致

```

## 关于StorageClass回收策略对数据的影响

### 第一种配置

```yaml
   archiveOnDelete: "false"  
   reclaimPolicy: Delete   #默认没有配置,默认值为Delete
```

测试结果:

```txt
1.pod删除重建后数据依然存在,旧pod名称及数据依然保留给新pod使用
2.sc删除重建后数据依然存在,旧pod名称及数据依然保留给新pod使用
3.删除PVC后,PV被删除且NFS Server对应数据被删除
```

### 第二种配置

```yaml
   archiveOnDelete: "false"  
   reclaimPolicy: Retain
```

测试结果:

```txt
1.pod删除重建后数据依然存在,旧pod名称及数据依然保留给新pod使用
2.sc删除重建后数据依然存在,旧pod名称及数据依然保留给新pod使用
3.删除PVC后,PV不会别删除,且状态由Bound变为Released,NFS Server对应数据被保留
4.重建sc后,新建PVC会绑定新的pv,旧数据可以通过拷贝到新的PV中
```

### 第三种配置
```yaml
   archiveOnDelete: "ture"  
   reclaimPolicy: Retain
```

结果:
```
1.pod删除重建后数据依然存在,旧pod名称及数据依然保留给新pod使用
2.sc删除重建后数据依然存在,旧pod名称及数据依然保留给新pod使用
3.删除PVC后,PV不会别删除,且状态由Bound变为Released,NFS Server对应数据被保留
4.重建sc后,新建PVC会绑定新的pv,旧数据可以通过拷贝到新的PV中
```

### 第四种配置

```yaml
  archiveOnDelete: "ture"
  reclaimPolicy: Delete
```

结果:

```txt
1.pod删除重建后数据依然存在,旧pod名称及数据依然保留给新pod使用
2.sc删除重建后数据依然存在,旧pod名称及数据依然保留给新pod使用
3.删除PVC后,PV不会别删除,且状态由Bound变为Released,NFS Server对应数据被保留
4.重建sc后,新建PVC会绑定新的pv,旧数据可以通过拷贝到新的PV中
```

**总结:** 除以第一种配置外,其他三种配置在PV/PVC被删除后数据依然保留


## 错误

```txt
4 pod has unbound immediate PersistentVolumeClaims. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

查看nfs 日志得到报错

```txt
provision "default/test-claim" class "managed-nfs-storage": unexpected error getting claim reference: selfLink was empty, can't make reference
```

镜像需要用比较新的

kubernetes1.20在v1.20之后默认删除了 metadata.selfLink 字段，然而，部分应用仍然依赖于这个字段，例如 nfs-client-provisioner； 需要在/etc/kubernetes/manifests/kube-apiserver.yaml 添加 - --feature-gates=RemoveSelfLink=false 重新启用metadata.selfLink字段, k8s1.24.0 版本默认是true,不支持修改为false,否则apiserver会启动失败！

```yaml
spec:
  containers:

- command:
  - kube-apiserver
  - --feature-gates=RemoveSelfLink=false

```

重新启动

```bash
kubectl apply -f /etc/kubernetes/manifests/kube-apiserver.yaml
```
