---
title: centos7内网yum源搭建
date: 2022-09-19 09:43
categories:
- centos7
tags:
- yum
---
  
  
摘要: centos7内网yum源搭建
<!-- more -->

## 前言

架设镜像站点适用于内网及隔离网络，使用rsync同步官方源没问题，但是同步国内的yum源时出现了同步不起的问题，所以改用reposync的方式。

配置内网yum仓库，实际上就是把网络镜像源的软件包下载到本地服务器，生成repodata数据，内网主机通过读取这台服务的repodata。

## 配置镜像服务器的yum源

配置内网yum服务器的镜像源，用于下载网络上的软件包

```bash
# 安装阿里镜像源
# 下载阿里镜像源
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
# 下载阿里epel源
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

# 删除缓存
yum clean all
# 更新缓存
yum makecache
# 查看镜像源列表
yum repolist
# 安装同步工具
yum install -y yum-utils
# 安装repo制作工具
yum install -y createrepo
# 安装nginx
yum install -y nginx

# 创建镜像仓库存储路径,空间尽量大些
mkdir -p /data/yum/mirrors/7/repo/

# 通过reposync命令工具获取外网YUM源所有软件包，-r指定repolist id，默认不加-r表示获取外网所有YUM软件包，-p参数表示指定下载软件的路径
# 下载rpm包，之后可以用下边的命令同步远程仓库最新数据包
reposync --repoid=base -p /data/yum/mirrors/7/repo/
reposync --repoid=extras -p /data/yum/mirrors/7/repo/
reposync --repoid=updates -p /data/yum/mirrors/7/repo/
reposync --repoid=epel -p /data/yum/mirrors/7/repo/

# 给每个仓库都生成repodata
createrepo /data/yum/mirrors/7/repo/base/
createrepo /data/yum/mirrors/7/repo/extras/
createrepo //data/yum/mirrors/7/repo/updates/
createrepo //data/yum/mirrors/7/repo/epel/
```

reposync 选项

|选项|描述|
|---|---|
|-r / --repoid| 指定repolist id |
|-p | 指定下载软件的路径,默认为当前目录 |
|--download-metadata | 下载元信息 |
|-n / --newest-only | 只下载最新软件包 |

---


### update.sh

```bash
#!/bin/bash

set -e

datetime=$(date +"%Y-%m-%d")

mirrorsDir="/ztocwst/yum/mirrors/7/repo/"

mirrors=("base" "extras" "updates" "epel")

exec > /var/log/centosrepo.log

for val in "${mirrors[@]}"; do
  reposync --gpgcheck -l -n --repoid="${val}" --download-metadata -p $mirrorsDir
  #同步镜像源
  if [ $? -eq 0 ]; then
    createrepo --update "${mirrorsDir}${val}"
    #每次添加新的rpm时,必须更新索引信息
    echo "SUCESS: ${datetime} ${val} update successful"
  else
    echo "ERROR: ${datetime} ${val} update failed"
  fi

done
```

弃用

```bash
#!/bin/bash
echo 开始同步ubuntu
apt-mirror
echo ubuntu同步结束

echo 开始同步centos7
reposync --gpgcheck -l  -n --repoid=extras --repoid=updates --repoid=base --repoid=epel  --download-metadata -p /data/yum/mirrors/
echo centos7同步结束

#更新元数据
createrepo --update /data/yum/mirrors/7/repo/base/
createrepo --update /data/yum/mirrors/7/repo/extras/
createrepo --update /data/yum/mirrors/7/repo/updates/
createrepo --update /data/yum/mirrors/7/repo/epel/

```

---

### nginx autoindex theme

#### 配置nginx

```nginx
server {
    listen       80;
    server_name  mirrors.test.com;
    root         /ztocwst/yum/mirrors;   #这里是yum源存放目录


    location /yum { 
        autoindex on;           #打开目录浏览功能
        autoindex_exact_size off;  # off：以可读的方式显示文件大小
        autoindex_localtime on; # on、off：是否以服务器的文件时间作为显示的时间

        add_before_body /.theme/header.html;
        add_after_body /.theme/footer.html;


        charset utf-8,gbk; #展示中文文件名
        client_max_body_size 4G;
        alias /ztocwst/yum/mirrors/yum/;
    }
    
    location / {    #文档页面
        index index.html;
    }

    # 禁止访问的文件或目录
    location ~ ^/(\.user.ini|\.htaccess|\.git|\.svn|\.project|LICENSE|RESDME.md) {
      return 404;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }   
}

```


#### 配置文档页面

index 页面

```bash
cd /ztocwst/yum/mirrors
mkdir css help

vim index.html
```

```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>CentOS镜像使用帮助</title>
    <link
      rel="stylesheet"
      type="text/css"
      href="./css/mirror.css"
      media="screen"
    />
    <link rel="shortcut icon" href="/.media/favicon.ico" />
  </head>
  <body>
    <h1>CentOS镜像使用帮助</h1>

    <div id="mirror-usage">
      <h2>仓库</h2>
      <ul>
        <li><a href="/yum">CentOS7</a></li>
      </ul>

      <h2>使用说明</h2>

      <p>首先备份/etc/yum.repos.d/CentOS-Base.repo</p>
      <pre>
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup</pre
      >
      <h3>方式一</h3>
      <p>下载对应版本repo文件, 放入/etc/yum.repos.d/(操作前请做好相应备份)</p>
      <ul>
        <li><a href="./help/CentOS7-Base-lan.repo">CentOS7</a></li>
      </ul>
      <p>运行以下命令生成缓存</p>
      <pre>
curl -o /etc/yum.repos.d/CentOS7-Base-lan.repo http://mirrors.ztoyc.zt/help/CentOS7-Base-lan.repo
yum clean all
yum makecache</pre
      >

      <h3>方式二</h3>
      <p>复制repo内容, 粘贴到/etc/yum.repos.d/repo文件(操作前请做好相应备份)</p>
      <pre>
[base]
name=CentOS-Base
baseurl=http://mirrors.ztoyc.zt/yum/7/repo/base/
enabled=1
gpgcheck=0
repo_gpgcheck=0

[updates]
name=CentOS-Updates
baseurl=http://mirrors.ztoyc.zt/yum/7/repo/updates/
enabled=1
gpgcheck=0
repo_gpgcheck=0

[extras]
name=CentOS-Extras
baseurl=http://mirrors.ztoyc.zt/yum/7/repo/extras/
enabled=1
gpgcheck=0
repo_gpgcheck=0

[epel]
name=CentOS-Epel
baseurl=http://mirrors.ztoyc.zt/yum/7/repo/epel/
enabled=1
gpgcheck=0
repo_gpgcheck=0

[docker-ce]
name=docker-ce
baseurl=http://mirrors.ztoyc.zt/yum/7/repo/docker-ce-stable/
enabled=1
gpgcheck=0
repo_gpgcheck=0

[kubernetes]
name=kubernetes
baseurl=http://mirrors.ztoyc.zt/yum/7/repo/kubernetes/
enabled=1
gpgcheck=0
repo_gpgcheck=0
      </pre>
    </div>
    <div class="hr"><hr /></div>

    <div id="footer">
      <p id="copyright">Centos7 yum 仓库</p>
    </div>
  </body>
</html>

```

repo 文件

```
vim help/CentOS7-Base-lan.repo
```

```ini
[base]
name=CentOS-Base
baseurl=http://mirrors.ztoyc.zt/yum/7/repo/base/
enabled=1
gpgcheck=0
repo_gpgcheck=0

[updates]
name=CentOS-Updates
baseurl=http://mirrors.ztoyc.zt/yum/7/repo/updates/
enabled=1
gpgcheck=0
repo_gpgcheck=0

[extras]
name=CentOS-Extras
baseurl=http://mirrors.ztoyc.zt/yum/7/repo/extras/
enabled=1
gpgcheck=0
repo_gpgcheck=0

[epel]
name=CentOS-Epel
baseurl=http://mirrors.ztoyc.zt/yum/7/repo/epel/
enabled=1
gpgcheck=0
repo_gpgcheck=0

[docker-ce]
name=docker-ce
baseurl=http://mirrors.ztoyc.zt/yum/7/repo/docker-ce-stable/
enabled=1
gpgcheck=0
repo_gpgcheck=0

[kubernetes]
name=kubernetes
baseurl=http://mirrors.ztoyc.zt/yum/7/repo/kubernetes/
enabled=1
gpgcheck=0
repo_gpgcheck=0
```


#### 配置主题

```bash
cd /data/yum/mirrors/

mkdir .theme/css
cd .theme
```

页面

```html
vim .theme/header.html


<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<link rel="stylesheet" href="/.theme/style.css">
		<link rel="stylesheet" href="/.theme/icons.css">
	</head>
<body>
<div id="page">
```

```css
/* vim .theme/style.css    */

* {
  margin: 0;
  padding: 0
}

html {
  -webkit-text-size-adjust: 100%;
  -ms-text-size-adjust: 100%;
}

body {
  min-width: 320px;
  margin: 1em;
  color: #333;
  background-color: #eee;
  font-size: 120%;
        font-weight: bold;
  background: #fff;
  background-size: 100% 100%;
  font-family: "Bitstream Vera Sans", "Lucida Grande", Verdana, Lucida, sans-serif;
  line-height: 0.8;
}

a {
  color: #0000FF;
  text-decoration: none;
}

a:hover {
  color: #000;
}

h1 {
  padding: 1em;
  color: #555;
  font-size: 80%;
  font-weight: 400;
}

hr {
  display: block;
  margin: 0 -1px;
  border-top: 1px solid #ddd;
  border-bottom: none;
}

pre {
  overflow: auto;
  margin: 1.5em;
  line-height: 1.4em;
}

footer {
  margin: 1em;
  color: #888;
  font-size: 80%;
}

#page {
  overflow: hidden;
  background-color: #fff;
  background: rgba(255,255,255,0.8);
  border-radius: 5px;
  box-shadow: 0 0 3px #ccc;
}
```


```css
/* vim .them/icons.css */

pre a[href]:before,
pre a[href$="/"]:before {
	content: "";
	width: 16px;
	height: 16px;
	display: inline-block;
	vertical-align: middle;
	margin: 0 5px 0 0;
	/* padding: 5px 25px 0 0; */
	background-repeat: no-repeat;
	background-position: left bottom;
}

a[href]:before {
	/*background: url('icons/empty.png');*/
	background: url('icons/none.png');
}

a[href$="/"]:before {
	background: url('icons/folder.png');
}


/** Checksums **/

a[href~="MD5"]:before,
a[href~="SHA1"]:before,
a[href~="SHA256"]:before {
	background: url('icons/lock.png');
}

a[href$=".md5"]:before,
a[href$=".sha1"]:before,
a[href$=".sha256"]:before {
	background: url('icons/lock2.png');
}

a[href$=".pgp"]:before,
a[href$=".asc"]:before,
a[href$=".sig"]:before {
	background: url('icons/lock3.png');
}


/** Compressed **/

a[href$=".7z"]:before {
	background: url('icons/7z.png');
}

a[href$=".bin"]:before,
a[href$=".cue"]:before {
	background: url('icons/bin.png');
}

a[href$=".deb"]:before {
	background: url('icons/deb.png');
}

a[href$=".iso"]:before {
	background: url('icons/iso.png');
}

a[href$=".rar"]:before {
	background: url('icons/rar.png');
}

a[href$=".rpm"]:before {
	background: url('icons/rpm.png');
}

a[href$=".tar"]:before,
a[href$=".xz"]:before,
a[href$=".txz"]:before {
	background: url('icons/tar.png');
}

a[href$=".tgz"]:before,
a[href$=".gz"]:before {
	background: url('icons/tgz.png');
}

a[href$=".zip"]:before {
	background: url('icons/zip.png');
}

a[href$=".apk"]:before {
	background: url('icons/android.png');
}

a[href$=".bz2"]:before,
a[href$=".bz2"]:before
a[href$=".tbz2"]:before {
	background: url('icons/bz2.png');
}


/** Data Storage **/

a[href$=".csv"]:before {
	background: url('icons/csv.png');
}

a[href$=".ini"]:before {
	background: url('icons/ini.png');
}

a[href$=".json"]:before {
	background: url('icons/json.png');
}

a[href$=".sql"]:before {
	background: url('icons/sql.png');
}

a[href$=".sqlite"]:before {
	background: url('icons/sqlite.png');
}

a[href$=".reg"]:before {
	background: url('icons/reg.png');
}

a[href$=".xml"]:before {
	background: url('icons/xml.png');
}

a[href$=".yaml"]:before,
a[href$=".yml"]:before {
	background: url('icons/yaml.png');
}


/** Documents **/

a[href$=".chm"]:before {
	background: url('icons/chm.png');
}

a[href$=".djvu"]:before {
	background: url('icons/djvu.png');
}

a[href$=".mobi"]:before {
	background: url('icons/mobi.png');
}

a[href$=".pdf"]:before {
	background: url('icons/pdf.png');
}

a[href$=".txt"]:before {
	background: url('icons/text.png');
}

a[href$=".rtf"]:before {
	background: url('icons/rtf.png');
}

a[href$=".doc"]:before {
	background: url('icons/doc.png');
}

a[href$=".epub"]:before {
	background: url('icons/epub.png');
}


/** Information **/

a[href~="README"]:before {
	background: url('icons/readme.png');
}

a[href~="CHANGELOG"]:before {
	background: url('icons/changelog.png');
}

a[href~="INSTALL"]:before {
	background: url('icons/install.png');
}

a[href~="LICENSE"]:before {
	background: url('icons/license.png');
}

a[href~="COPYING"]:before {
	background: url('icons/copying.png');
}

a[href$=".nfo"]:before,
a[href$=".diz"]:before {
	background: url('icons/nfo.png');
}


/** Media Files **/

a[href$=".flac"]:before {
	background: url('icons/flac.png');
}

a[href$=".mp3"]:before {
	background: url('icons/mp3.png');
}

a[href$=".wav"]:before {
	background: url('icons/wav.png');
}

a[href$=".bmp"]:before {
	background: url('icons/bmp.png');
}

a[href$=".gif"]:before {
	background: url('icons/gif.png');
}

a[href$=".jpg"]:before,
a[href$=".jpeg"]:before {
	background: url('icons/jpg.png');
}

a[href$=".png"]:before {
	background: url('icons/png.png');
}

a[href$=".psd"]:before {
	background: url('icons/psd.png');
}

a[href$=".ra"]:before,
a[href$=".rv"]:before {
	background: url('icons/rp.png');
}

a[href$=".avi"]:before {
	background: url('icons/avi.png');
}

a[href$=".flv"]:before {
	background: url('icons/flv.png');
}

a[href$=".mkv"]:before {
	background: url('icons/mkv.png');
}

a[href$=".mov"]:before {
	background: url('icons/mov.png');
}

a[href$=".mp4"]:before {
	background: url('icons/mp4.png');
}


/** Source Code **/

a[href$=".sh"]:before {
	background: url('icons/bash.png');
}

a[href$=".cpp"]:before {
	background: url('icons/cpp.png');
}

a[href$=".h"]:before {
	background: url('icons/header.png');
}

a[href$=".c"]:before {
	background: url('icons/c-lang.png');
}

a[href$=".go"]:before {
	background: url('icons/go-lang.png');
}

a[href$=".html"]:before,
a[href$=".htm"]:before {
	background: url('icons/html.png');
}

a[href$=".java"]:before,
a[href$=".jar"]:before,
a[href$=".class"]:before {
	background: url('icons/java.png');
}

a[href$=".lua"]:before {
	background: url('icons/lua.png');
}

a[href$=".nim"]:before {
	background: url('icons/nim.png');
}

a[href$=".js"]:before {
	background: url('icons/javascript.png');
}

a[href$=".php"]:before {
	background: url('icons/php.png');
}

a[href$=".pl"]:before {
	background: url('icons/perl.png');
}

a[href$=".py"]:before {
	background: url('icons/python.png');
}

a[href$=".rb"]:before {
	background: url('icons/ruby.png');
}

a[href$=".rs"]:before,
a[href$=".rlib"]:before {
	background: url('icons/rust.png');
}

a[href$=".css"]:before {
	background: url('icons/css.png');
}

a[href$=".less"]:before {
	background: url('icons/less.png');
}

```


icon 文件

```
https://github.com/silvus/nginx-autoindex-theme.git

将 icons 目录复制到 .theme/  中
```