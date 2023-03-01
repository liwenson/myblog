#!/bin/bash

VMId=9004
VMName=centos-template-002
Mem=2048
CPU=2
MAC=CE:13:DC:5D:93:68
Bridge="vmbr0"
Storage="sas-storage"
Image="centos-image.qcow2"
ImagePath="/opt/images"

IP=""
GW=""

qm create $VMId --name "$VMName" --memory $Mem --cores $CPU --net0 virtio=$MAC,bridge=$Bridge --onboot 1 --agent 1
qm importdisk $VMId $ImagePath/$Image $Storage
qm set $VMId --scsihw virtio-scsi-pci --scsi0 $Storage:vm-$VMId-disk-0
qm set $VMId --ide2 $Storage:cloudinit
qm set $VMId --boot c --bootdisk scsi0
qm set $VMId --serial0 socket --vga serial0

if [[ $IP != "" ]] && [[ $GW != "" ]]; then
  qm set $VMId --ipconfig0 ip=$IP,gw=$GW
fi

qm set $VMId --ciuser=root
qm set $VMId --cipassword=ztyc1234
