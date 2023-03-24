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

## 关闭浏览器后后台执行并保存结果

关掉浏览器的话进程不会结束，已经在运行的 notebook 和里面的 cell 还会继续运行。

关掉浏览器再打开之前还在运行的 notebook 的话，就看不到里面正在运行的 cell 打印的最新的结果了，所以我们需要保存结果。

可以考虑用 python 的 logging，可以把你想要打印的都写在一个日志文件里，这样你关掉浏览器也没关系了。

代码的话比如这样

``` python
import logging
import sys
import datetime

def init_logger(filename, logger_name):
    '''
    @brief:
        initialize logger that redirect info to a file just in case we lost connection to the notebook
    @params:
        filename: to which file should we log all the info
        logger_name: an alias to the logger
    '''

    # get current timestamp
    timestamp = datetime.datetime.utcnow().strftime('%Y%m%d_%H-%M-%S')
    
    logging.basicConfig(
        level=logging.INFO, 
        format='[%(asctime)s] %(name)s {%(filename)s:%(lineno)d} %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(filename=filename),
            logging.StreamHandler(sys.stdout)
        ]
    )

    # Test
    logger = logging.getLogger(logger_name)
    logger.info('### Init. Logger {} ###'.format(logger_name))
    return logger

```

# Initialize

```python
my_logger = init_logger("./ml_notebook.log", "ml_logger")
```


这样就可以在每一次训练结束的时候，把训练结果用 my_logger.info(“...”) 打印到当前路径下的 ml_notebook.log 的文件里了，每一行还会标好这一行打印的时间，也就是上面 logging.basicConfig 里 format 定义的格式。当然你也可以自己定义自己习惯的格式。

配合 jupyter notebook 的 magic command，还可以把每个 cell 运行的时间记录并且打印到日志文件里。比如在第一个 cell 里：

```
%%capture out
%%timeit
a = 1+1

```

然后在下一个 cell 里：

```python
my_logger.info("capture & timeit: "+out.stdout)
```

就能知道上一个 cell 运行了多久了。
