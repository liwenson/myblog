#!/bin/bash -xe

VMId=$(pvesh get /cluster/nextid)

createVm() {
  VMName=$1
  Cores=$2
  Mem=$(($3 * 1024))
  VlanID=$4
  OSType=$5

  if [ "$6" != "" ]; then
    PASSWORD="$6"
  else
    PASSWORD="pSEqXW5AOyJReBVY"
  fi

  OSDsikSize="$7"

  DsikSize="$8"

  IP="${9}"
  GW="${10}"
  Tag="${11}"

  {

    Bridge="vmbr0"
    Storage="local-lvm"
    ImagePath="/opt/image"

    case $OSType in
    "Centos")
      Image_FILE_PATH="${ImagePath}/centos-image.qcow2"
      # shift # past argument=value
      ;;
    "Ubuntu")
      Image_FILE_PATH="${ImagePath}/ubuntu-22.04-server-cloudimg-amd64.img"
      # shift # past argument=value
      ;;
    "Windows")
      Image_FILE_PATH="${ImagePath}/windows-image.qcow2"
      # shift # past argument=value
      ;;
    *)
      # unknown option
      ;;
    esac

    # echo "${VMName}" $Mem "${Cores}" $Bridge $Storage "${VMId}" "${OSType}" "${VlanID}" "${Image_FILE_PATH}" "${PASSWORD}"

    echo 10

    ### 创建命令

    # 创建VM
    qm create "${VMId}" --name "${VMName}" --memory "${Mem}" --cores "${Cores}" --cpu host --net0 virtio,bridge="${Bridge}",tag="${VlanID}" --onboot 1 --agent 1
    echo 20
    # 导入OS硬盘
    qm importdisk "${VMId}" "${Image_FILE_PATH}" "${Storage}"
    qm set "${VMId}" --scsihw virtio-scsi-pci --scsi0 ${Storage}:vm-"${VMId}"-disk-0
    # 调整OS硬盘大小
    qm disk resize "${VMId}" scsi0 "${OSDsikSize}G"
    # 创建第二块磁盘
    if [ "${DsikSize}" != "" ]; then
      qm set "${VMId}" --scsi1 ${Storage}:"${DsikSize}"
    fi

    echo 50
    qm set "${VMId}" --ide2 ${Storage}:cloudinit

    if [ "${IP}" != "" ] && [ "${GW}" != "" ]; then
      qm set "${VMId}" --ipconfig0 ip="${IP}",gw="${GW}"
    fi

    echo 60
    # 配置启动项
    qm set "${VMId}" --boot c --bootdisk scsi0
    # 配置显示接口
    qm set "${VMId}" --serial0 socket --vga serial0
    echo 80
    # 配置用户名和密码
    qm set "${VMId}" --ciuser=root
    qm set "${VMId}" --cipassword="${PASSWORD}"
    if [ "${Tag}" != "" ]; then
      qm set "${VMId}" --tags "${Tag}"
    fi
    echo 100
  } | whiptail --gauge "请等待虚拟机的创建..." 10 60 0
  # whiptail --title "Create pve VM" --msgbox "${VMName} 虚拟机创建完成" 12 60

  # whiptail --title "虚拟机创建完成" --msgbox "$(qm config VMId | grep -v sshkeys | column -t -s' ')" 20 70
  whiptail --title "虚拟机创建完成" --msgbox "$(qm config "${VMId}" | grep -v sshkeys | grep -v meta | grep -v scsihw | grep -v boot | grep -v cipassword | grep -v ciuser | grep -v smbios1 | grep -v vmgenid | column -t -s' ')" 20 70
}

viewGui() {
  # VMName=$(whiptail --title "Create pve VM" --inputbox "虚拟机名称" 10 60 3>&1 1>&2 2>&3)
  if ! VMName=$(whiptail --title "Create pve VM" --inputbox "虚拟机名称" 10 60 3>&1 1>&2 2>&3); then
    whiptail --title "Create pve VM" --msgbox "虚拟机创建终止..." 10 60
    exit 1
  fi

  if ! Cores=$(whiptail --title "Create pve VM" --inputbox "CPU核数(num)" 10 60 2 3>&1 1>&2 2>&3); then
    whiptail --title "Create pve VM" --msgbox "虚拟机创建终止..." 10 60
    exit 1
  fi

  if ! MemTmp=$(whiptail --title "Create pve VM" --inputbox "内存(GB)" 10 60 2 3>&1 1>&2 2>&3); then
    whiptail --title "Create pve VM" --msgbox "虚拟机创建终止..." 10 60
    exit 1
  fi

  if ! OSType=$(whiptail --title "Create pve VM" --radiolist "请选择系统镜像" 10 60 5 \
    "Centos" "centos7 镜像" ON \
    "Ubuntu" "Ubuntu2204 镜像" OFF \
    "Windows" "Windows 镜像暂未支持" OFF 3>&1 1>&2 2>&3); then
    whiptail --title "Create pve VM" --msgbox "虚拟机创建终止..." 10 60
    exit 1
  fi

  if ! OSDsikSize=$(whiptail --title "Create pve VM" --inputbox "OS(系统)硬盘大小(GB)" 10 60 50 3>&1 1>&2 2>&3); then
    whiptail --title "Create pve VM" --msgbox "虚拟机创建终止..." 10 60
    exit 1
  fi

  if (whiptail --title "Create pve VM" --no-button "No" --yes-button "Yes" --yesno "是否创建数据盘?" 10 60); then
    DsikSize=$(whiptail --title "Create pve VM" --inputbox "硬盘大小(GB)" 10 60 100 3>&1 1>&2 2>&3)
  else
    DsikSize=""
  fi

  if ! VlanID=$(whiptail --title "Create pve VM" --radiolist "选择网络?" 10 60 5 \
    "84" "测试网络" OFF \
    "83" "研发网络" OFF \
    "91" "生产网络" OFF \
    "184" "(私有云)测试网络" ON \
    "183" "(私有云)研发网络" OFF \
    "191" "(私有云)生产网络" OFF \
    "192" "(私有云)运维网络" OFF \
    3>&1 1>&2 2>&3); then
    whiptail --title "Create pve VM" --msgbox "虚拟机创建终止..." 10 60
    exit 1
  fi

  if (whiptail --title "Create pve VM" --yes-button "Yes" --no-button "No" --yesno "是否使用DHCP" 10 60); then
    IP=""
    GW=""
  else
    until [ "$yn" == "yes" ] || [ "$yn" == "YES" ]; do
      if ! IP=$(whiptail --title "Create pve VM" --inputbox "请填写一个vlan ${VlanID} 网络下的ip\nIP/掩码(192.168.10.10/24)" 10 60 3>&1 1>&2 2>&3); then
        whiptail --title "Create pve VM" --msgbox "虚拟机创建终止..." 10 60
        exit 1
      fi
      if (echo "${IP}" | grep -oEq '([0-9]{1,3}.?){4}/[0-9]{2}'); then
        if ! GW=$(whiptail --title "Create pve VM" --inputbox "网关" 10 60 3>&1 1>&2 2>&3); then
          whiptail --title "Create pve VM" --msgbox "虚拟机创建终止..." 10 60
          exit 1
        fi
        yn=yes
      else
        whiptail --title "Create pve VM" --msgbox "${IP} 格式不正确,请使用ip加掩码的方式: 192.168.10.1/24" 10 60
      fi
    done
  fi

  if (whiptail --title "Create pve VM" --yes-button "Yes" --no-button "No" --yesno "是否使用默认Root密码?" 10 60); then
    PASSWORD=""
  else
    if ! PASSWORD=$(whiptail --title "Create pve VM" --passwordbox "输入Root密码." 10 60 3>&1 1>&2 2>&3); then
      whiptail --title "Create pve VM" --msgbox "虚拟机创建终止..." 10 60
      exit 1
    fi
  fi

  if ! Tags=$(whiptail --title "Create pve VM" --inputbox "标签(选填，使用逗号(,)分割)" 10 60 3>&1 1>&2 2>&3); then
    whiptail --title "Create pve VM" --msgbox "虚拟机创建终止..." 10 60
    exit 1
  fi

  Info=$(echo -e "主机名: ${VMName}\nCPU: ${Cores}\n内存: ${MemTmp}G\n网络: ${VlanID}\n系统: ${OSType}\n系统盘: ${OSDsikSize}G\n数据盘: ${DsikSize}G" | column -t -s' ')
  whiptail --title "虚拟机清单" --msgbox "${Info}" 15 65

  if (whiptail --title "Create pve VM" --yes-button "Yes" --no-button "No" --yesno "开始创建?" 10 60); then
    createVm "$VMName" "$Cores" "$MemTmp" "$VlanID" "$OSType" "$PASSWORD" "$OSDsikSize" "$DsikSize" "${IP}" "${GW}" "${Tags}"
  else
    whiptail --title "Create pve VM" --msgbox "虚拟机创建终止..." 10 60
    exit 1
  fi
}

main() {
  viewGui
}

main
