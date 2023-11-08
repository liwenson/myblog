---
title: k8s 开启临时容器
date: 2023-05-31 14:24
categories:
- k8s
tags:
- tag
---
  
  
摘要: desc
<!-- more -->


工作中在调试集群中未包含bash sh等工具的pod往往比较麻烦，k8s提供了一个临时容器供我们添加到要调试的pod中进行工作。

### 什么是临时容器？

临时容器与其他容器的不同之处在于，它们缺少对资源或执行的保证，并且永远不会自动重启， 因此不适用于构建应用程序。 临时容器使用与常规容器相同的 ContainerSpec 节来描述，但许多字段是不兼容和不允许的。

    临时容器没有端口配置，因此像 ports，livenessProbe，readinessProbe 这样的字段是不允许的。
    Pod 资源分配是不可变的，因此 resources 配置是不允许的。
    有关允许字段的完整列表，请参见 EphemeralContainer 参考文档。

临时容器是使用 API 中的一种特殊的 ephemeralcontainers 处理器进行创建的， 而不是直接添加到 pod.spec 段，因此无法使用 kubectl edit 来添加一个临时容器。

与常规容器一样，将临时容器添加到 Pod 后，将不能更改或删除临时容器。

使用临时容器需要开启 EphemeralContainers 特性门控， kubectl 版本为 v1.18 或者更高。

临时容器不被静态 Pod 支持。

### 临时容器的用途

- 当由于容器崩溃或容器镜像不包含调试工具而导致 kubectl exec 无用时， 临时容器对于交互式故障排查很有用。
- 尤其是，Distroless 镜像 允许用户部署最小的容器镜像，从而减少攻击面并减少故障和漏洞的暴露。 由于 distroless
镜像不包含 Shell 或任何的调试工具，因此很难单独使用 kubectl exec 命令进行故障排查。
- 使用临时容器时，启用 进程名字空间共享 很有帮助，可以查看其他容器中的进程。



### 开启EphemeralContainers

#### 在kubeadm 创建k8s 时开启

```
kubeadm init \
    --apiserver-advertise-address="$k8sApi" \
    --apiserver-cert-extra-sans=127.0.0.1 \
    --image-repository=registry.aliyuncs.com/google_containers \
    --ignore-preflight-errors=all \
    --kubernetes-version="$k8sversion" \
    --v 5 \
    --service-cidr=10.10.0.0/16 \
    --pod-network-cidr=10.18.0.0/16 \
    --feature-gates=EphemeralContainers=true  # 用来描述各种功能特性的键值
```


#### master节点上操作

- 修改apiserver

```
编辑 /etc/kubernetes/manifests/kube-apiserver.yaml

将 --feature-gates=TTLAfterFinished=true 修改为--feature-gates=TTLAfterFinished=true,EphemeralContainers=true
```

- 修改controller-manager

```
编辑 /etc/kubernetes/manifests/kube-controller-manager.yaml

将 --feature-gates=TTLAfterFinished=true  修改为  --feature-gates=TTLAfterFinished=true,EphemeralContainers=true
```

- 修改kube-scheduler

```
编辑/etc/kubernetes/manifests/kube-scheduler.yaml

将--feature-gates=TTLAfterFinished=true   修改为   --feature-gates=TTLAfterFinished=true,EphemeralContainers=true 
```

#### 所有的节点上操作

- 修改kubelet

```
编辑 /var/lib/kubelet/kubeadm-flags.env

添加  --feature-gates=EphemeralContainers=true

```

修改后如下

```
KUBELET_KUBEADM_ARGS="--cgroup-driver=systemd --network-plugin=cni --pod-infra-container-image=k8s.gcr.io/pause:3.2 --feature-gates=EphemeralContainers=true"
```

重启kubelet


```
systemctl daemon-reload
systemctl restart kubelet
```

### 验证

#### 开启之前

```
kubectl debug -it <POD_NAME> --image=busybox
```

如果未启用该功能，您将看到类似下面的消息。

```
Defaulting debug container name to debugger-wg54p.
error: ephemeral containers are disabled for this cluster (error from server: "the server could not find the requested resource").

```

#### 开启之后验证

创建了一个pod，pod中运行的镜像不包含任何调试程序 ，我们无法进入调试

```
kubectl run ephemeral-demo --image=k8s.gcr.io/pause:3.2 --restart=Never
```


```
kubectl  get pod ephemeral-demo   -o json|jq .spec
---

{
  "containers": [
    {
      "image": "k8s.gcr.io/pause:3.2",
      "imagePullPolicy": "IfNotPresent",
      "name": "ephemeral-demo",
      "resources": {},
      "terminationMessagePath": "/dev/termination-log",
      "terminationMessagePolicy": "File",
      "volumeMounts": [
        {
          "mountPath": "/var/run/secrets/kubernetes.io/serviceaccount",
          "name": "default-token-4jhw7",
          "readOnly": true
        }
      ]
    }
  ],
  "dnsPolicy": "ClusterFirst",
  "enableServiceLinks": true,
  "nodeName": "node-02",
  "preemptionPolicy": "PreemptLowerPriority",
  "priority": 0,
  "restartPolicy": "Never",
  "schedulerName": "default-scheduler",
  "securityContext": {},
  "serviceAccount": "default",
  "serviceAccountName": "default",
  "terminationGracePeriodSeconds": 30,
  "tolerations": [
    {
      "effect": "NoExecute",
      "key": "node.kubernetes.io/not-ready",
      "operator": "Exists",
      "tolerationSeconds": 300
    },
    {
      "effect": "NoExecute",
      "key": "node.kubernetes.io/unreachable",
      "operator": "Exists",
      "tolerationSeconds": 300
    }
  ],
  "volumes": [
    {
      "name": "default-token-4jhw7",
      "secret": {
        "defaultMode": 420,
        "secretName": "default-token-4jhw7"
      }
    }
  ]
}
```

进入容器,现在容器是不支持进入的

```
# kubectl  exec -it ephemeral-demo  -- sh
---

OCI runtime exec failed: exec failed: container_linux.go:380: starting container process caused: exec: "sh": executable file not found in $PATH: unknown
command terminated with exit code 126

# kubectl  exec -it ephemeral-demo  -- bash
---
OCI runtime exec failed: exec failed: container_linux.go:380: starting container process caused: exec: "bash": executable file not found in $PATH: unknown
command terminated with exit code 126
```

创建一个临时容器添加到这个pod里

加上-i参数将直接进入添加的临时容器的控制台界面，因为是使用 kubectl run 创建的pod ,所以需要-target 参数指定另一个容器的进程命名空间。 因为 kubectl run 不能在它创建的pod中启用 共享进程命名空间。

```
# kubectl debug -it ephemeral-demo --image=busybox --target=ephemeral-demo
---

Defaulting debug container name to debugger-nkrn9.
If you don't see a command prompt, try pressing enter.
/ # ls
bin   dev   etc   home  proc  root  sys   tmp   usr   var
/ # 

```


我们此时再去看pod 的信息会发现已经被添加了一个类型为ephemeralContainers的容器

```
#  kubectl  get pod ephemeral-demo   -o json|jq .spec
---

{
  "containers": [
    {
      "image": "k8s.gcr.io/pause:3.2",
      "imagePullPolicy": "IfNotPresent",
      "name": "ephemeral-demo",
      "resources": {},
      "terminationMessagePath": "/dev/termination-log",
      "terminationMessagePolicy": "File",
      "volumeMounts": [
        {
          "mountPath": "/var/run/secrets/kubernetes.io/serviceaccount",
          "name": "default-token-4jhw7",
          "readOnly": true
        }
      ]
    }
  ],
  "dnsPolicy": "ClusterFirst",
  "enableServiceLinks": true,
  "ephemeralContainers": [
    {
      "image": "busybox",
      "imagePullPolicy": "Always",
      "name": "debugger-nkrn9",
      "resources": {},
      "stdin": true,
      "targetContainerName": "ephemeral-demo",
      "terminationMessagePath": "/dev/termination-log",
      "terminationMessagePolicy": "File",
      "tty": true
    }
  ],
  "nodeName": "node-02",
  "preemptionPolicy": "PreemptLowerPriority",
  "priority": 0,
  "restartPolicy": "Never",
  "schedulerName": "default-scheduler",
  "securityContext": {},
  "serviceAccount": "default",
  "serviceAccountName": "default",
  "terminationGracePeriodSeconds": 30,
  "tolerations": [
    {
      "effect": "NoExecute",
      "key": "node.kubernetes.io/not-ready",
      "operator": "Exists",
      "tolerationSeconds": 300
    },
    {
      "effect": "NoExecute",
      "key": "node.kubernetes.io/unreachable",
      "operator": "Exists",
      "tolerationSeconds": 300
    }
  ],
  "volumes": [
    {
      "name": "default-token-4jhw7",
      "secret": {
        "defaultMode": 420,
        "secretName": "default-token-4jhw7"
      }
    }
  ]
}
```

### 创建pod的副本进行调试

有些时候 Pod 的配置参数使得在某些情况下很难执行故障排查。 例如，在容器镜像中不包含 shell 或者你的应用程序在启动时崩溃的情况下， 就不能通过运行 kubectl exec 来排查容器故障。 在这些情况下，你可以使用 kubectl debug 来创建 Pod 的副本，通过更改配置帮助调试。

例如我们以go-7c9c5496fb-dbrv5这个pod 为基础复制了一个名为myapp-debug的pod 并添加了一个临时容器nginx

```
# kubectl  get pod
---

NAME                               READY   STATUS    RESTARTS   AGE
check-ecs-price-7cdc97b997-khvg2   1/1     Running   1          3h53m
go-7c9c5496fb-dbrv5                1/1     Running   0          29m
web-show-768dd97986-nrg9t          1/1     Running   0          3h53m


# kubectl  debug go-7c9c5496fb-dbrv5  --image=nginx --share-processes --copy-to=myapp-debug
---

Defaulting debug container name to debugger-67hrx.


# kubectl  exec -it myapp-debug -c debugger-67hrx  -- bash
---

root@myapp-debug:/# ls
bin  boot  dev  docker-entrypoint.d  docker-entrypoint.sh  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var


root@myapp-debug:/# cat /etc/nginx/
conf.d/         fastcgi_params  mime.types      modules/        nginx.conf      scgi_params     uwsgi_params    

root@myapp-debug:/# ls /etc/nginx/  
conf.d  fastcgi_params  mime.types  modules  nginx.conf  scgi_params  uwsgi_param
```
