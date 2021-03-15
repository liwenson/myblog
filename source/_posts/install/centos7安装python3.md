---
title: Centos7安装python3
date: 2020-12-12 15:32
categories:
- centos7
tags:
- python
---
  
  
摘要:  Centos7 安装pyhton3 环境
<!-- more -->


### 依赖准备
```
yum -y groupinstall "Development tools"
yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel
yum install -y libffi-devel zlib1g-dev
yum install zlib* -y
```


### python3下载页面
```
https://www.python.org/downloads/source/
```
```
wget https://www.python.org/ftp/python/3.9.0/Python-3.9.0.tar.xz
```

`注意`： gcc 4.8.5不适用于编译Python3.8 及以上版本，但是可以编译Python 3.7。 使用GCC9.2来编译Python3.9
```
tar -xvJf  Python-3.9.0.tar.xz
```
创建编译安装目录
```
mkdir /usr/local/python3 
```

### 安装
```
cd Python-3.9.0
./configure --prefix=/usr/local/python3 --enable-optimizations --with-ssl

#第一个指定安装的路径,不指定的话,安装过程中可能软件所需要的文件复制到其他不同目录,删除软件很不方便,复制软件也不方便.
#第二个可以提高python10%-20%代码运行速度.
#第三个是为了安装pip需要用到ssl,后面报错会有提到.

make && make install
```

创建软链接
```
ln -s /usr/local/python3/bin/python3 /usr/local/bin/python3
ln -s /usr/local/python3/bin/pip3 /usr/local/bin/pip3
```

验证是否成功
```
python3 -V
pip3 -V
```

### 修改pip 源
```
cd ~
mkdir .pip
cd .pip
vim pip.conf

#进入后添加以下内容,保存退出.
[global]
index-url = https://mirrors.aliyun.com/pypi/simple
```

### 修改pipenv安装源

在自己的虚拟环境中找到Pipfile文件,将其中的url = "https://pypi.org/simple" 修改为你需要的国内镜像,如 https://mirrors.aliyun.com/pypi/simple/
```
[root@localhost myproject]# vim Pipfile 


[[source]]
name = "pypi"
url = "https://pypi.org/simple" # 改为url = "https://mirrors.aliyun.com/pypi/simple/"
verify_ssl = true

[dev-packages] #这里是开发环境专属包,使用pipenv install --dev package来安装专属开发环境的包

[packages] # 全部环境的通用包,安装在这里.

[requires]
python_version = "3.9"
```

### 报错处理

```
zipimport.ZipImportError: can't decompress data; zlib not available Makefile:1099: recipe for target 'install' failed make: *** [install] Error 1
```
解决方式
```
yum -y install zlib1g-dev
```

```
ModuleNotFoundError: No module named '_ctypes'
```
解决方式
```
yum -y install libffi-devel
```


### 配置python 项目环境


#### 创建python3 项目环境
```
cd /opt
python3 -m venv py3

```

#### 创建项目目录
```
cd /opt/
mkdir myapp
source /opt/py3/bin/activate
```

#### 自动激活项目环境
```
cd /opt/
git clone https://github.com/kennethreitz/autoenv.git

# 进入项目路径
cd myapp
vim .env
source /opt/py3/bin/activate

# 在环境变量添加
echo "source /opt/autoenv/activate.sh" >> /root/.bashrc

```





