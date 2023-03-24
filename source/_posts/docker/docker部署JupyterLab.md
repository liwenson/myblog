---
title: 使用docker-compose部署JupyterLab
date: 2023-03-21 10:47
categories:
- docker
tags:
- JupyterLab
---
  
  
摘要: desc
<!-- more -->

## 官方提供了几个镜像

    jupyter/base-notebook
    jupyter/minimal-notebook
    jupyter/r-notebook
    jupyter/scipy-notebook
    jupyter/tensorflow-notebook
    jupyter/datascience-notebook
    jupyter/pyspark-notebook
    jupyter/all-spark-notebook

第一个为基础镜像，就是只包含基本的notebook功能。第二个在第一个的基础上安装了一些工具，具体装了啥可以看dockerfile。其他的就是安装了一些第三方Python库

## 运行参数

参数：

    NotebookApp.password：notebook访问密码
    NotebookApp.allow_password_change：是否允许远程修改密码
    NotebookApp.allow_remote_access：这个不知道是啥意思，反正我每次都加了
    NotebookApp.open_browser：是否打开浏览器，这个在容器里默认就是False，所以可以不加
    NotebookApp.notebook_dir：notebook工作目录

其中password后面的混淆串，需要用IPython.lib.passwd()生成。它在包ipython里，因此在安装了里面执行即可。下面是在命令行执行的例子。

NotebookApp.password 后面不是跟的明文，需要运行下面两行Python代码设置之后，复制返回值

```py
# Fenced
from notebook.auth import passwd

passwd()

```

或者

```shell
pip install ipython
python -c "import IPython;print(IPython.lib.passwd())"
```

```shell
mkdir -p jupyter/data/work
chmod 777 jupyter/data/work
```

## docker-compose

```yaml
vim jupyter/docker-compose.yml

---
version: '3.1'
services:
  jellyfin:
    image: jupyter/tensorflow-notebook:latest  
    restart: "unless-stopped"
    container_name: jupyter
    ports:
      - 8888:8888
    environment:
      - "JUPYTER_ENABLE_LAB=yes"  # 如果不需要jupyter lab,改成yes就可以了
      - "RESTARTABLE=yes"
    command: start-notebook.sh --NotebookApp.password='sha1:6fc67477a931:5bfac3b859fb0ebca59703588a8c844cd7129ee5'
    volumes:
      - data/work:/home/jovyan/work
    # 支持GPU，需要支持gpu的镜像
    deploy:
      resources:
        reservations:
          devices:
          -  driver: nvidia
             count: all
             capabilities: [gpu]
```

docker 命令运行

```bash
docker run -it --rm --gpus all -v $PWD:/tf/notebooks -p 8888:8888 tensorflow/tensorflow:2.2.2-gpu-py3-jupyter
```

进入笔记本后可以导入tensorflow并查看GPU是否可用

```python
import tensorflow as tf
tf.config.list_physical_devices('GPU')
```

容器日志中的密码

链接中的97c99de9e4b3ea86ebf567d8e1290c11023d165b7351156c 就是访问的token


## 错误

```
ERROR: The Compose file './docker-compose.yml' is invalid because:
services.jupyter.deploy.resources.reservations value Additional properties are not allowed ('devices' was unexpected)
```

需要docker-compose 1.28 以上
