#!/bin/bash

baseDir="/opt/dd-script-image"
jarDir="/opt/dd-script-jar"

jarPath="/opt/program/gatewayOTA"

function generation_batchNumber() {
  # curl 命令获取参数
  echo "写入批次号"
  echo "${batch}" >/mnt/opt/config/batch.txt
}

function changeEnv() {
  # curl 命令获取参数
  if [ ! -n "${envArgs}" ]; then
    echo "环境参数为空,跳过修改"
  else
    echo "修改环境参数"
    # sed -i s/test2/"${envArgs}"/ /mnt/opt/config/restart.sh
    if ! sed -i '/ENV=/ c 'ENV=$envArgs /mnt/opt/script/restart.sh; then
      exit 1
    fi
  fi
}

function addJar() {
  # 创建目录
  # 创建初始目录
  if [ ! -d "${jarPath}" ]; then
    mkdir -p "${jarPath}/target-1.0.26"
  fi

  local jar="$(ls -t ${jarPath} | sort -r | head -n 1)"
  \cp -f "${jarDir}/${jar}" "${jarPath}/target-1.0.26"

  # 创建软链接
  ln -sf /opt/program/gatewayOTA/target-1.0.26 /opt/program/gatewayOTA/target

}

function mount_TF_Card() {
  local mount_disk="/dev/${1}2"
  echo "挂载 ${mount_disk}"

  if mount "${mount_disk}" /mnt; then
    echo " ${mount_disk} mount success "
  else
    echo " ${mount_disk} mount fail "
    exit 1
  fi
}

function eject() {
  # u盘弹出
  local eject_disk="/dev/$1"
  local umount_disk="/dev/${1}2"

  echo "弹出 ${eject_disk}"

  if umount "${umount_disk}"; then
    echo "${umount_disk} umount success"
  else
    echo "${umount_disk} umount fail"
  fi

  if udisksctl power-off -b "${eject_disk}"; then
    echo "${eject_disk} Eject success"
  else
    echo "${eject_disk} Eject fail"
  fi

}

function write_image() {
  #  写入镜像
  local of_disk="/dev/$1"
  echo " 镜像写入 ${of_disk} "

  while true; do

    image="$(ls -t ${baseDir} | sort -r | head -n 1)"

    if [ "${image##*.}" = "gz" ]; then
      echo "解压镜像 ${image}"
      gzip -d "${baseDir}/${image}"
      # pv "${baseDir}/${image}" | gzip -d -c > "${image%*.gz}"
    fi

    if [ "${image##*.}" = "img" ]; then
      break
    fi

  done
  echo "写入镜像 ${image}"
  if pv -cN write <"${baseDir}/${image}" | dd of="${of_disk}" bs=2048k; then
    echo "Image write success"
  else
    echo "Image write success fail"
    exit 1
  fi

}

function check_TF_Card() {
  # 检查磁盘是不是U盘
  disks=()
  local disk_list=()
  while IFS='' read -r line; do disk_list+=("$line"); done < <(lsblk | grep disk | grep -v "0B" | grep -v "4k" | grep -v "sda" | awk '{print $1}')

  for ((i = 0; i < ${#disk_list[@]}; i++)); do
    local disk="${disk_list[$i]}"
    if cat /sys/block/"$disk"/removable >/dev/null 2>&1; then
      if [[ "$(cat /sys/block/"$disk"/removable)" -eq 1 ]]; then
        echo "检查到可移动磁盘 ${disk} "
        disks+=("$disk")
      else
        echo "$disk 2"
      fi
    fi
  done

}

function view() {

  # 批次号
  if ! batch=$(whiptail --title "刻录脚本" --inputbox "请将 批次号 填在输入框中" 10 60 "$(date +'%Y%m%d')" 3>&1 1>&2 2>&3); then
    whiptail --title "刻录脚本" --msgbox "刻录脚本终止..." 10 60
    exit 1
  fi

  # 批次号检查
  if ! (echo "${batch}" | grep -Pq "^((19|20)\d{2})((?:0?[1-9])|(?:1[0-2]))((?:0?[1-9])|(?:[1-2][0-9])|30|31)$"); then
    whiptail --title "刻录脚本" --msgbox "序列号格式错误 ${batch}\n请输入正确的粘液日格式: 20230425" 10 60
    exit 1
  fi

  # 环境参数
  if ! envArgs=$(whiptail --title "刻录脚本" --inputbox "请将 环境参数 填在输入框中\n可以为空,为空将不改变环境参数" 10 60 3>&1 1>&2 2>&3); then
    whiptail --title "刻录脚本" --msgbox "刻录脚本终止..." 10 60
    exit 1
  fi

}

function init_dir() {
  # 创建初始目录
  if [ ! -d "${baseDir}" ]; then
    mkdir "${baseDir}"
  fi

  if [ ! -d "${jarDir}" ]; then
    mkdir "${jarDir}"
  fi

  if [ "$(ls ${baseDir} | wc -l)" -eq 0 ]; then
    whiptail --title "刻录脚本" --msgbox "请将 镜像放入到 ${baseDir} 中..." 10 60
    exit 1
  fi

  if [ "$(ls ${jarDir} | wc -l)" -eq 0 ]; then
    whiptail --title "刻录脚本" --msgbox "请将 Java程序放入到 ${jarDir} 中..." 10 60
    exit 1
  fi

}

function soft() {
  # 检查命令是否存在
  if ! (which pv); then
    apt install pv -y
  fi

  if ! (which gzip); then
    apt install gzip -y
  fi

}

function main() {
  init_dir
  soft
  check_TF_Card
  view

  echo "批次号: ${batch}"
  echo "环境: ${envArgs}"
  echo "可移动磁盘数量: ${#disks[@]}"

  if [ ${#disks[@]} -eq 0 ]; then
    echo "没有检测到可移动磁盘"
    whiptail --title "刻录脚本" --msgbox "没有检测到可移动磁盘..." 10 60
    exit 1
  else
    for ((i = 0; i < ${#disks[@]}; i++)); do
      local disk="${disks[$i]}"
      local diskSize=$(lsblk | grep disk | grep "${disk}" | awk '{print $4}')

      if ! (whiptail --title "刻录脚本" --msgbox "磁 盘: ${disk} ${diskSize} \n批次号: ${batch}\n环 境: ${envArgs}" 10 60); then
        exit 1
      fi

      if ! (whiptail --title "刻录脚本" --yes-button "Yes" --no-button "No" --yesno "开始执行脚本?" 10 60); then
        whiptail --title "刻录脚本" --msgbox "脚本终止..." 10 60
        exit 1
      fi

      write_image "${disk}"
      mount_TF_Card "${disk}"
      generation_batchNumber
      changeEnv
      addJar

      eject "${disk}"

      echo "刻录完成"
    done
  fi

}

main
