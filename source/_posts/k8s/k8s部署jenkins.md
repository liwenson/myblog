---
title: k8s中部署jenkins
date: 2022-04-06 17:57
categories:
- k8s
tags:
- jenkins
---
  
  
摘要: desc
<!-- more -->

## 准备nfs

略

## namespace

```bash
vim jenkins-namespace.yaml
```

```yaml
jenkins-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: jenkins-ns
  labels:
    app: jenkins
```

## RBAC

```bash
vim jenkins-rbac.yaml
```

```yaml
---
# namespace
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins-sa
  namespace: jenkins-ns

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
   name: jenkins-cr
   namespace: jenkins-ns
rules:
  - apiGroups: ["extensions", "apps"]
    resources: ["deployments"]
    verbs: ["create", "delete", "get", "list", "watch", "patch", "update"]
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["create", "delete", "get", "list", "watch", "patch", "update"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["create","delete","get","list","patch","update","watch"]
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create","delete","get","list","patch","update","watch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get","list","watch"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: jenkins-crd
roleRef:
  kind: ClusterRole
  name: jenkins-cr
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: jenkins-sa
  namespace: jenkins-ns

```

## PVC

jenkins 存储

```bash
vim jenkins-storage.yaml
```

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
  namespace: jenkins-ns
spec:
  #storageClassName: nfs-client-storageclass
  storageClassName: nfs-sc
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
```

maven 缓存

```bash
vim jenkins-maven-cache.yaml
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: maven-cache-pvc
  namespace: jenkins-ns
spec:
  storageClassName: nfs-sc
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
```

## deploy

```bash
vim jenkins-deploy.yaml
```

```yaml
---
apiVersion: apps/v1 
kind: Deployment
metadata:
  name: jenkins
  namespace: jenkins-ns
spec:
  selector:
    matchLabels:
      app: jenkins
  replicas: 1
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      terminationGracePeriodSeconds: 10
      serviceAccount: jenkins-sa
      containers:
      - name: jenkins
        image: bitnami/jenkins:2.332.2
        imagePullPolicy: IfNotPresent
        env:
        - name: JAVA_OPTS
          value: -XshowSettings:vm -Dhudson.slaves.NodeProvisioner.initialDelay=0 -Dhudson.slaves.NodeProvisioner.MARGIN=50 -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85 -Duser.timezone=Asia/Shanghai -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8
        ports:
        - containerPort: 8080
          name: web
          protocol: TCP
        - containerPort: 50000
          name: agent
          protocol: TCP
        resources:
          limits:
            cpu: "2000m"
            memory: 4Gi
          requests:
            cpu: "2000m"
            memory: 2Gi
        livenessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 130
          timeoutSeconds: 5
          failureThreshold: 12
        readinessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 120
          timeoutSeconds: 5
          failureThreshold: 12
        volumeMounts:
        - name: jenkinshome
          mountPath: /bitnami/jenkins/home
      securityContext:
        fsGroup: 1000
      volumes:
      - name: jenkinshome
        persistentVolumeClaim:
          claimName: jenkins-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: jenkins-srv
  namespace: jenkins-ns
  labels:
    app: jenkins
spec:
  selector:
    app: jenkins
  type: NodePort
  ports:
  - name: web
    port: 8080
    targetPort: web
    nodePort: 30002
  - name: agent
    port: 5000
    targetPort: agent
    nodePort: 5000
```

创建

```bash
kubectl apply -f ./
```

访问 nodeIP:30002

```txt
user / bitnami
```

## jenkins 接入k8s

系统设置 --> 配置 --> Cloud -->  The cloud configuration has moved to a separate configuration page.

填写下面信息

kubernetes
名称： kubernetes

Kubernetes 地址
Kubernetes api地址:
<http://10.200.92.60:8080>

Kubernetes 命名空间
jenkins-ns

jenkins 地址
<http://10.200.92.60:30002/>

## jenkisn gitops

系统管理 --> 系统配置 --> Global Pipeline Libraries

Name: k8s_shareLibrary

Default version: master

Retrieval method: Modern SCM

Source Code Management: git

项目仓库: 仓库地址 <http://10.200.92.11:3000/root/k8s-jenkins-shareLibrary.git>

凭据: git凭据

## 数据迁移

config.xml
jobs
credentials.xml
plugins
