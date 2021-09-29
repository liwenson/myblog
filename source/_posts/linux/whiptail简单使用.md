---
title: whiptail简单使用
date: 2021-09-29 09:40
categories:
- linux
tags:
- whiptail
---
	
	
摘要: desc
<!-- more -->

```
#!/bin/bash
# Version 1.0
# AUTHOR:Xin23 http://weibo.com/231988
PV() {
	NextLine() {
		echo ' '
	}
	Split() {
		echo '-----------------------------------------------------------------------'
	}
	EchoTitle() {
		echo "--------$Title-----------------------------------------"
	}
	ShowPVFirstMenu() {
		echo '
       Physical Volumn Main Menu
       Input Number To Choose!
       Create Physical Volumn ...... 1
       Remove Physical Volumn ...... 2
       Change Physical Volumn ...... 3
       Show   Physical Volumn ...... 4
       Scan   Physical Volumn ...... 5
       Exit                   ...... 6'
		NextLine
	}
	GetChoice() {
		read -p '       Input Your Choice: ' Var
		NextLine
	}
	ConfirmOperate() {
		NextLine
		echo "  Continue               ...... y
       Return                 ...... n"
		NextLine
		GetChoice
		NextLine
		Run
	}
	Run() {
		if [ $Var == y ]; then
			$Parameter $Disk
		elif [ $Var == n ]; then
			Split
			PV
		else
			ConfirmOperate
		fi
	}
	ChooseDisk() {
		read -p "       Please Choose Disk:    (Example: /dev/sdc)       " Disk
		NextLine
	}
	PVChange() {
		echo '  Which Operate You Want To do ?  '
		NextLine
		echo '        ENABLE  Allocatable    ...... y
       DISABLE Allocatable    ...... n'
		NextLine
		GetChoice
	}
	CheckPVChange() {
		if [ $Var == y ]; then
			Parameter='pvchange -x y'
		elif [ $Var == n ]; then
			Parameter='pvchange -x n'
		else
			PVChange
		fi
	}
	PVShow() {
		echo '  Which Physical Volumn You Want To Show ?        '
		NextLine
		echo '          All    Physical Volumn ...... 1
       Single Physical Volumn ...... 2'
		NextLine
		GetChoice
	}
	CheckPVShow() {
		if [ $Var -eq 1 ]; then
			pvdisplay
		elif [ $Var -eq 2 ]; then
			pvdisplay $Disk
		fi
	}
	TestPVShow() {
		if [ $Var -eq 1 ]; then
			Disk=All
		elif [ $Var -eq 2 ]; then
			EchoTitle
			NextLine
			ChooseDisk
		fi
	}

	ShowPVFirstMenu
	GetChoice
	case $Var in
	"1")
		Title='Create Physical Volumn'
		Parameter=pvcreate
		EchoTitle
		NextLine
		ChooseDisk
		echo "  Disk $Disk Will Be Convert To Physical Volumn"
		ConfirmOperate
		Status=0
		;;
	"2")
		Title='Remove Physical Volumn'
		EchoTitle
		Parameter=pvremove
		NextLine
		ChooseDisk
		echo "  Disk $Disk Will Be Remove From Physical Volumn"
		ConfirmOperate
		Status=0
		;;
	"3")
		Title='Change Physical Volumn'
		EchoTitle
		NextLine
		PVChange
		CheckPVChange
		NextLine
		ChooseDisk
		echo "  Physical Volumn $Disk Will Be Change"
		ConfirmOperate
		Status=0
		;;
	"4")
		Title='Show   Physical Volumn'
		EchoTitle
		NextLine
		PVShow
		NextLine
		TestPVShow
		echo "  Physical Volumn $Disk Will Be Show"
		NextLine
		CheckPVShow
		Status=0
		;;
	"5")
		Title='Scan   Physical Volumn'
		EchoTitle
		NextLine
		pvscan
		Status=0
		;;
	"6")
		exit 0
		;;
	*)
		echo '  Input Error,Retype!'
		PV
		;;
	esac
	NeedContinue() {
		if [ $Status -eq 0 ]; then
			NextLine
			Split
			PV
		fi
	}
	NeedContinue
}

PV

```

----------------------

```
#!/bin/bash
# Version 1.0
# AUTHOR:

#显示分组中的服务器
view_args() {
	ascription=$(whiptail --title "归属项目设置" --inputbox "该项目所属项目组" 10 60 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
	pname=$(whiptail --title "项目设置" --inputbox "项目名称" 10 60 3>&1 1>&2 2>&3)
		if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
	git_url=$(whiptail --title "项目GIT地址" --inputbox "Git地址" 10 60 3>&1 1>&2 2>&3)
		if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
	env=$(whiptail --title "项目环境设置" --inputbox "请您输入该项目的环境" 10 60 3>&1 1>&2 2>&3)
		if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
	type=$(whiptail --title "项目类型设置" --menu "请您选择该项目的类型" 10 60 4 \
		"Frontnd" "前端项目" \
		"BackEnd" "后端项目" 3>&1 1>&2 2>&3)
			if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
	root_project_path=$(whiptail --title "项目环境设置" --inputbox "部署脚本根目录" 10 60 "/tmp/deploy" 3>&1 1>&2 2>&3)
		if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
	back_dir=$(whiptail --title "项目环境设置" --inputbox "项目备份路径" 10 60 "/ztocwst/back" 3>&1 1>&2 2>&3)
		if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
}

view_project() {

	if [ ${type} == "Frontnd" ]; then
		echo ""
		fed_project_cmd=$(whiptail --title "前端项目设置" --inputbox "前端项目编译命令" 10 60 3>&1 1>&2 2>&3)
			if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
		project_out=$(whiptail --title "前端项目设置" --inputbox "前端项目编译输出路径" 10 60 "dist" 3>&1 1>&2 2>&3)
			if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
		site_root=$(whiptail --title "前端项目设置" --inputbox "前端项目Nginx指向路径" 10 60 "/ztocwst/nginx/www" 3>&1 1>&2 2>&3)
			if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
		domain_name=$(whiptail --title "前端项目设置" --inputbox "前端项目Nginx域名" 10 60 3>&1 1>&2 2>&3)
			if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
	else
		echo ""
		project_cmd=$(whiptail --title "后端项目设置" --inputbox "后端项目编译命令" 10 60 3>&1 1>&2 2>&3)
			if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
		project_out=$(whiptail --title "后端项目设置" --inputbox "后端项目编译输出路径" 10 60 3>&1 1>&2 2>&3)
			if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
		src_project_path=$(whiptail --title "后端项目设置" --inputbox "后端项目路径" 10 60 "/ztocwst/service" 3>&1 1>&2 2>&3)
			if [ $? -eq 1 ];then
			whiptail --title "提示！" --msgbox "欢迎您再次使用初始化脚本." 10 60
			exit 1
	fi
	fi

}

outconfig() {
	if [ ${type} == "Frontnd" ]; then
		echo ""
		mv vars.yml vars.yml-$(date +%Y%m%d%H%M)
cat > vars.yml <<EOF
# *项目环境
env: "${env}"

# *项目类型  fed- , tomcat# 前端项目使用
type: "fed-"  

# *归属项目
ascription: "${ascription}"

# *名称
pname: "${pname}"

# 域名
domain_name: "${domain_name}"

# 前端项目 编译命令
fed_project_cmd: ${fed_project_cmd}

# *项目git地址
git_url:  "${git_url}"

# *输出路径前端一般是 dist
project_out: "${project_out}"

# 项目脚本路径
local_project_path: "{{ root_project_path }}/{{ ascription }}/{{ env }}/{{ project_name }}"

# 项目名称
project_name: "{{ type }}{{ env }}-ztocwst-{{ ascription }}-{{ pname }}"


# nginx www路径
site_root: "${site_root}"

##############  全局参数
# 部署脚本根目录
root_project_path: "${root_project_path}"

# 备份路径
back_dir: "${back_dir}"

EOF

	else
		echo ""
		mv vars.yml vars.yml-$(date +%Y%m%d%H%M)
cat > vars.yml <<EOF
# *项目环境
env: "${env}"

# *项目类型  fed- , tomcat
type: ""


# *归属项目
ascription: "${ascription}"

# *名称
pname: "${pname}"


# *后端编译命令
project_cmd: "${project_cmd}"


# *项目git地址
git_url:  "${git_url}"

# *编译输出路径
project_out: "${project_out}"


# 项目脚本路径
local_project_path: "{{ root_project_path }}/{{ ascription }}/{{ env }}/{{ project_name }}"

# 项目名称
project_name: "{{ type }}{{ env }}-ztocwst-{{ ascription }}-{{ pname }}"



##############  全局参数
# 部署脚本根目录
root_project_path: "${root_project_path}"

# 备份路径
back_dir: "${back_dir}"

# 后端目标服务器项目路径
src_project_path: "${src_project_path}"

EOF

	fi
}


main(){
	view_args
	view_project
	outconfig
}

main
```

-----------------

```
#!/bin/bash
function Prompt(){
(whiptail --title "IP地址更改(yes/no)" --yesno "您是否需要重新配置IP地址？" 10 60)
    if [ $? -eq 0 ];then
        ip_check
    else
        whiptail --title "Nginx提示！" --msgbox "欢迎您再次使用Nginx一键安装服务." 10 60
        exit 1
    fi
}

function ip_check(){
IP=$(whiptail --title "IP地址设置" --inputbox "请您输入您的IP地址" 10 60  3>&1 1>&2 2>&3)
    VALID_CHECK=$(echo $IP|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
        if echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
            if [[ "$VALID_CHECK" == "yes" ]]; then
                whiptail --title "IP地址合法提示！" --msgbox "您输入的IP地址正确，点击OK进行下一步配置！." 10 60
            fi
        else
                whiptail --title "IP地址错误提示！" --msgbox "您输入的IP地址可能有误,请您检查后再次输入！." 10 60
                Prompt
        fi
}

function install_nginx(){
(whiptail --title "安装 Nginx？(yes/no)" --yesno "你是否需要安装Nginx？" 10 60)
    if [ $? -eq 0 ];then
            {
                sleep 1
                echo 5
                apt-get update >/dev/null
                sleep 1
                echo 10
                sudo apt-get -y install  build-essential >/dev/null &
                sleep 1
                echo 30
                sudo apt-get -y install openssl libssl-dev >/dev/null &
                sleep 1
                echo 50
                sudo apt-get -y install libpcre3 libpcre3-dev >/dev/null &
                sleep 1
                echo 70
                sudo apt-get -y install zlib1g-dev >/dev/null &
                sleep 1
                echo 90
                wget -q  http://nginx.org/download/nginx-1.12.2.tar.gz >/dev/null  
                sleep 1
                echo 95
                useradd -M -s /sbin/nologin nginx &
                tar zxf /root/nginx-1.12.2.tar.gz && cd /root/nginx-1.12.2/ && 
                ./configure --prefix=/usr/local/nginx --with-http_dav_module --with-http_stub_status_module --with-http_addition_module --with-http_sub_module  --with-http_flv_module --with-http_mp4_module --with-pcre --with-http_ssl_module --with-http_gzip_static_module  --user=nginx >/dev/null && make >/dev/null && make install >/dev/null
                /usr/local/nginx/sbin/nginx &>/dev/null &
                sleep 100
            } |  whiptail --gauge "正在安装Nginx,过程可能需要几分钟请稍后.........." 6 60 0 &&  whiptail --title "Nginx安装成功提示！！！" --msgbox "恭喜您Nginx安装成功，请您访问：http://$IP:80, 感谢使用~~~" 10 60 
    else
        whiptail --title "Nginx提示！！！" --msgbox "感谢使用~~~" 10 60
        exit 1
    fi
}

function mail(){
    ip_check
    install_nginx
}

mail

```