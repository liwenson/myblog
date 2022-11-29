---
title: gcc 升级
date: 2020-09-21 16:34
categories:
- centos7
tags:
- gcc
---

```bash
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

```bash
yum groupinstall "Development Tools"
```

**查看默认动态库:**

```bash
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

```txt
http://ftp.gnu.org/gnu/gcc/
```

```bash
curl -O https://ftp.gnu.org/gnu/gcc/gcc-11.3.0/gcc-11.3.0.tar.xz
tar xvf gcc-11.3.0.tar.xz
```

**安装gcc的依赖软件，gcc的软件包内提供了自动下载需要软件的脚本\**./contrib/download_prerequisites\****   这个过程会持续很久，根据网络情况

网络差可以将离线包放在gcc-9.3.0目录下即可

```bash
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

**生成Makefile文件:**

```bash
./configure --prefix=/usr/local --enable-bootstrap -enable-checking=release -enable-languages=c,c++ -disable-multilib

```

```bash
./configure --prefix=/usr/local --enable-bootstrap -enable-checking=release -enable-languages=c,c++ -disable-multilib --host=x86_64
```



**编译gcc:**

```bash
make -j4    #多核电脑可以添加 "-j4" , make对多核处理器的优化选项，此步骤非常耗时
```

编译报错需要指定平台

```txt
checking whether the C compiler works... yes
checking for C compiler default output file name... a.out
checking for suffix of executables... 
checking whether we are cross compiling... configure: error: in `/usr/local/src/gcc-11.3.0/host-x86_64-pc-linux-gnu/intl':
configure: error: cannot run C compiled programs.
If you meant to cross compile, use `--host'.
See `config.log' for more details
make[2]: *** [configure-stage1-intl] Error 1
make[2]: Leaving directory `/usr/local/src/gcc-11.3.0'
make[1]: *** [stage1-bubble] Error 2
make[1]: Leaving directory `/usr/local/src/gcc-11.3.0'
make: *** [all] Error 2
```

```txt
r_n.o iorn_n.o nior_n.o xor_n.o xnor_n.o copyi.o copyd.o zero.o sec_tabselect.o comb_tables.o add_n_sub_n.o
../libtool: line 1734: x86_64-ar: command not found
make[5]: *** [libmpn.la] Error 127
make[5]: Leaving directory `/usr/local/src/gcc-11.3.0/host-x86_64/gmp/mpn'
make[4]: *** [all-recursive] Error 1
make[4]: Leaving directory `/usr/local/src/gcc-11.3.0/host-x86_64/gmp'
make[3]: *** [all] Error 2
make[3]: Leaving directory `/usr/local/src/gcc-11.3.0/host-x86_64/gmp'
make[2]: *** [all-stage1-gmp] Error 2
make[2]: Leaving directory `/usr/local/src/gcc-11.3.0'
make[1]: *** [stage1-bubble] Error 2
make[1]: Leaving directory `/usr/local/src/gcc-11.3.0'

```

**安装gcc**

```bash
make install


ls /usr/local/bin | grep gcc
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

ln -s libstdc++.so.6.0.27 libstdc++.so.6
"libstdc++.so.6" -> "libstdc++.so.6.0.27"


#export PATH=/usr/local/bin:$PATH  >> /etc/profile
```

重启系统

```bash
reboot



gcc -v

```

## cmake 安装

### 获取

```txt
https://cmake.org/download/

wget https://github.com/Kitware/CMake/releases/download/v3.20.0/cmake-3.20.0.tar.gz
```

### 编译

```bash
cd /usr/local/src
tar xf cmake-3.20.0.tar.gz
cd cmake-3.20.0
./configure --prefix=/usr/local/cmake
make && make install
```

### 软连接

```bash
ln -s /usr/local/cmake/bin/cmake /usr/bin/cmake
```

### 验证

```bash
cmake -version

...
cmake version 3.20.0

CMake suite maintained and supported by Kitware (kitware.com/cmake).
```
