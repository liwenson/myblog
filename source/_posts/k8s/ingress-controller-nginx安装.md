---
title: ingress-nginx部署
date: 2021-10-13 15:53
categories:
- k8s
tags:
- ingress
---
	
	
摘要: ingress-nginx部署
<!-- more -->


## 准备

清除namespace
```
kubectl delete namespaces ingress-nginx
```


k8s主机打标签
```
kubectl label node 10.200.92.61 isIngress="true"
kubectl label node 10.200.92.62 isIngress="true"
```


## 创建Ingress-controller资源对象


获取资源
```
wget  https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/mandatory.yaml

```

对下载的yaml文件进行简单的修改
```
vim mandatory.yaml


apiVersion: v1
kind: Namespace
metadata:
  name: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---

kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: tcp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: udp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress-serviceaccount
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: nginx-ingress-clusterrole
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - endpoints
      - nodes
      - pods
      - secrets
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - services
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups:
      - "extensions"
      - "networking.k8s.io"
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - "extensions"
      - "networking.k8s.io"
    resources:
      - ingresses/status
    verbs:
      - update

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: nginx-ingress-role
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - pods
      - secrets
      - namespaces
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - configmaps
    resourceNames:
      # Defaults to "<election-id>-<ingress-class>"
      # Here: "<ingress-controller-leader>-<nginx>"
      # This has to be adapted if you change either parameter
      # when launching the nginx-ingress-controller.
      - "ingress-controller-leader-nginx"
    verbs:
      - get
      - update
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - create
  - apiGroups:
      - ""
    resources:
      - endpoints
    verbs:
      - get

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: nginx-ingress-role-nisa-binding
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: nginx-ingress-role
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: nginx-ingress-clusterrole-nisa-binding
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nginx-ingress-clusterrole
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---

apiVersion: apps/v1
#kind: Deployment
kind: DaemonSet
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
#  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
      app.kubernetes.io/part-of: ingress-nginx
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
      annotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
    spec:
      hostNetwork: true
      # wait up to five minutes for the drain of connections
      terminationGracePeriodSeconds: 300
      serviceAccountName: nginx-ingress-serviceaccount
      nodeSelector:
        isIngress: "true"
#        kubernetes.io/os: linux
      containers:
        - name: nginx-ingress-controller
          image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.29.0
          args:
            - /nginx-ingress-controller
            - --configmap=$(POD_NAMESPACE)/nginx-configuration
            - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
            - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
            - --publish-service=$(POD_NAMESPACE)/ingress-nginx
            - --annotations-prefix=nginx.ingress.kubernetes.io
          securityContext:
            allowPrivilegeEscalation: true
            capabilities:
              drop:
                - ALL
              add:
                - NET_BIND_SERVICE
            # www-data -> 101
            runAsUser: 101
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
            - name: https
              containerPort: 443
              protocol: TCP
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10
          lifecycle:
            preStop:
              exec:
                command:
                  - /wait-shutdown

---

apiVersion: v1
kind: LimitRange
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  limits:
  - min:
      memory: 90Mi
      cpu: 100m
    type: Container

```

```
kubectl apply -f mandatory.yaml

kubectl get daemonset -n ingress-nginx
NAME                       DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR    AGE
nginx-ingress-controller   2         2         2       2            2           isIngress=true   21h

kubectl get po -n ingress-nginx -o wide
NAME                             READY   STATUS    RESTARTS   AGE   IP             NODE           NOMINATED NODE   READINESS GATES
nginx-ingress-controller-47wkh   1/1     Running   0          66m   10.200.92.62   10.200.92.62   <none>           <none>
nginx-ingress-controller-thhj6   1/1     Running   0          66m   10.200.92.61   10.200.92.61   <none>           <none>

```

## 创建用于测试的Pod
### 创建第一个服务
```
vim httpd.yaml


apiVersion: v1
kind: Namespace
metadata:
  name: test-ns
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: httpd-01
  name: httpd01
  namespace: test-ns
spec:
  replicas: 2
  selector:
    matchLabels:
      app: httpd-01
  template:
    metadata:
      labels:
        app: httpd-01
    spec:
      containers:
      - name: httpd
        image: httpd
---
apiVersion: v1
kind: Service
metadata:
  name: httpd-svc
  namespace: test-ns
spec:
  selector:
    app: httpd-01
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```


### 创建第二个服务

```
vim tomcat.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: tomcat-01
  name: tomcat01
  namespace: test-ns
spec:
  replicas: 2
  selector:
    matchLabels:
      app: tomcat-01
  template:
    metadata:
      labels:
        app: tomcat-01
    spec:
      containers:
      - name: tomcat
        image: tomcat
---
apiVersion: v1
kind: Service
metadata:
  name: tomcat-svc
  namespace: test-ns
spec:
  selector:
    app: tomcat-01
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080

```

## 确保以上资源对象成功创建
```
kubectl get pod -n test-ns

NAME                       READY   STATUS    RESTARTS   AGE
httpd01-76b5c67784-2rbg2   1/1     Running   0          22h
httpd01-76b5c67784-xsfn9   1/1     Running   0          22h
tomcat01-744cdc454-7mmk9   1/1     Running   0          22h
tomcat01-744cdc454-hgwxs   1/1     Running   0          22h



kubectl get svc -n test-ns 

NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
httpd-svc    ClusterIP   10.0.0.130   <none>        80/TCP     22h
tomcat-svc   ClusterIP   10.0.0.71    <none>        8080/TCP   22h
```

## 创建Ingress资源对象
```
vim ingress.yaml

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: test-ingress
  namespace: test-ns
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: www.lzj.com
    http:
      paths:
      - path: /
        backend:
          serviceName: httpd-svc
          servicePort: 80
      - path: /tomcat
        backend:
          serviceName: tomcat-svc
          servicePort: 8080
  - host: www.zhj.com 
    http:
      paths:
      - path: /
        backend:
          serviceName: httpd-svc
          servicePort: 80
      - path: /tomcat
        backend:
          serviceName: tomcat-svc
          servicePort: 8080
```


```
kubectl apply -f ingress.yaml 
ingress.extensions/test-ingress created

kubectl get ingresses. -n test-ns
```


虽然访问到了对应的服务，但是有一个弊端，就是在做DNS解析的时候，只能指定Ingress-nginx容器所在的节点IP。而指定k8s集群内部的其他节点IP（包括master）都是不可以访问到的，如果这个节点一旦宕机，Ingress-nginx容器被转移到其他节点上运行（不考虑节点标签的问题，其实保持Ingress-nginx的yaml文件中默认的标签的话，那么每个节点都是有那个标签的）。随之还要我们手动去更改DNS解析的IP（要更改为Ingress-nginx容器所在节点的IP，通过命令 `kubectl get pod -n ingress-nginx -o wide `可以查看到其所在节点），很是麻烦。


```
client --->  ingress(80 / 443)  --> service --> pod
```

## 为Ingress-controller资源对象创建一个service资源对象

```
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/provider/baremetal/service-nodeport.yaml


cat service-nodeport.yaml 

apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  type: NodePort
  ports:
    - name: http
      port: 80
      targetPort: 80
			hostPort: 32000
      protocol: TCP
    - name: https
      port: 443
      targetPort: 443
			hostPort: 30443
      protocol: TCP
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
 
---

kubectl apply -f service-nodeport.yaml 
kubectl get svc -n ingress-nginx 

NAME            TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx   NodePort   10.0.0.133   <none>        80:32000/TCP,443:30443/TCP   91m
```

至此，这个 www.lzj.com 的域名即可和群集中任意节点的 32000/30443 端口进行绑定了


```
client ---> slb(80 / 443)  --> ingress(32000 / 30443)  --> service --> pod
```