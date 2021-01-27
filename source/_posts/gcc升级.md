---
title: gcc 升级
date: 2020-09-21 16:34
categories:
- gcc
tags:
- gcc
- linux
---

```
gcc -v

使用内建 specs。
COLLECT_GCC=gcc
COLLECT_LTO_WRAPPER=/usr/libexec/gcc/x86_64-redhat-linux/4.8.5/lto-wrapper
目标：x86_64-redhat-linux
配置为：../configure --prefix=/usr --mandir=/usr/share/man --infodir=/usr/share/info --with-bugurl=http://bugzilla.redhat.com/bugzilla --enable-bootstrap --enable-shared --enable-threads=posix --enable-checking=release --with-system-zlib --enable-__cxa_atexit --disable-libunwind-exceptions --enable-gnu-unique-object --enable-linker-build-id --with-linker-hash-style=gnu --enable-languages=c,c++,objc,obj-c++,java,fortran,ada,go,lto --enable-plugin --enable-initfini-array --disable-libgcj --with-isl=/builddir/build/BUILD/gcc-4.8.5-20150702/obj-x86_64-redhat-linux/isl-install --with-cloog=/builddir/build/BUILD/gcc-4.8.5-20150702/obj-x86_64-redhat-linux/cloog-install --enable-gnu-indirect-function --with-tune=generic --with-arch_32=x86-64 --build=x86_64-redhat-linux
线程模型：posix
gcc 版本 4.8.5 20150623 (Red Hat 4.8.5-39) (GCC)
```

**安装\**RHEL/C\*\*entos\*\*7\**默认的开发工具，包含gcc，g++,make等等一系列工具**

```
yum groupinstall "Development Tools"
```

**查看默认动态库：** 

```
strings /usr/lib64/libstdc++.so.6 | grep GLIBC

GLIBCXX_3.4
GLIBCXX_3.4.1
GLIBCXX_3.4.2
GLIBCXX_3.4.3
GLIBCXX_3.4.4
GLIBCXX_3.4.5
GLIBCXX_3.4.6
GLIBCXX_3.4.7
GLIBCXX_3.4.8
GLIBCXX_3.4.9
GLIBCXX_3.4.10
GLIBCXX_3.4.11
GLIBCXX_3.4.12
GLIBCXX_3.4.13
GLIBCXX_3.4.14
GLIBCXX_3.4.15
GLIBCXX_3.4.16
GLIBCXX_3.4.17
GLIBCXX_3.4.18
GLIBCXX_3.4.19
GLIBC_2.3
GLIBC_2.2.5
GLIBC_2.14
GLIBC_2.4
GLIBC_2.3.2
GLIBCXX_DEBUG_MESSAGE_LENGTH

```

**获取安装包并解压：**

```
http://ftp.gnu.org/gnu/gcc/
```

**安装gcc的依赖软件，gcc的软件包内提供了自动下载需要软件的脚本\**./contrib/download_prerequisites\****   这个过程会持续很久，根据网络情况

```
./contrib/download_prerequisites


2020-05-15 10:48:52 URL: ftp://gcc.gnu.org/pub/gcc/infrastructure/gmp-6.1.0.tar.bz2 [2383840] -> "./gmp-6.1.0.tar.bz2" [1]
2020-05-15 10:50:14 URL: ftp://gcc.gnu.org/pub/gcc/infrastructure/mpfr-3.1.4.tar.bz2 [1279284] -> "./mpfr-3.1.4.tar.bz2" [1]
2020-05-15 10:50:52 URL: ftp://gcc.gnu.org/pub/gcc/infrastructure/mpc-1.0.3.tar.gz [669925] -> "./mpc-1.0.3.tar.gz" [1]
2020-05-15 10:53:09 URL: ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2 [1658291] -> "./isl-0.18.tar.bz2" [1]
gmp-6.1.0.tar.bz2: 确定
mpfr-3.1.4.tar.bz2: 确定
mpc-1.0.3.tar.gz: 确定
isl-0.18.tar.bz2: 确定
All prerequisites downloaded successfully.

```

**生成Makefile文件**

```
./configure --prefix=/usr/local -enable-checking=release -enable-languages=c,c++ -disable-multilib

```

**编译gcc**

```
make -j4    #多核电脑可以添加 “-j4” ：make对多核处理器的优化选项，此步骤非常耗时

ls /usr/local/bin | grep gcc
```

**安装gcc**

```
 make install
```

**配置gcc**

```
cd ~
find /usr/local/src/gcc-9.2.0/ -name "libstdc++.so*"

/usr/local/src/gcc-9.2.0/stage1-x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.24
/usr/local/src/gcc-9.2.0/stage1-x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6
/usr/local/src/gcc-9.2.0/stage1-x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so
/usr/local/src/gcc-9.2.0/prev-x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.24
/usr/local/src/gcc-9.2.0/prev-x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6
/usr/local/src/gcc-9.2.0/prev-x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so
/usr/local/src/gcc-9.2.0/x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.24
/usr/local/src/gcc-9.2.0/x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6
/usr/local/src/gcc-9.2.0/x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so

cd /usr/lib64
cp /usr/local/src/gcc-9.2.0/stage1-x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.27 .
mv libstdc++.so.6 libstdc++.so.6.old
ln -sv libstdc++.so.6.0.27 libstdc++.so.6
"libstdc++.so.6" -> "libstdc++.so.6.0.27"
```



重启系统

```
reboot



gcc -v

```

