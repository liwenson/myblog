# _*_ coding:utf-8 _*_

import xlrd

#打开Excel文件(请注意在操作之前，关闭要操作的excel文件，不然会报错）
book = xlrd.open_workbook("abc.xlsx") #filename为文件名或者路径

# 获取所有的工作表
sheets = book.sheets()

 #获得book中所有工作表的名字
names = book.sheet_names()[0]
# print(names)

# 获取一个工作表
#table1 = book.sheets()[0]          		#通过索引顺序获取
#table1 = book.sheet_by_index(sheet_indx)  #通过索引顺序获取
table1 = book.sheet_by_name(names)	 #通过工作表名称获取

cmd = []

#行的操作
nrows = table1.nrows    #获取table1工作表内的有效行
for i in range(1,nrows):

  if i == 1:
    # 跳过第一行
    continue

  s = table1.row_values(i, start_colx=0, end_colx=None)
  VMId=int(s[4])
  VMName=s[1]
  Mem=int(s[5])*1024
  CPU=int(s[6])
  MAC=s[2]
  Bridge=s[7]
  Storage=s[9]
  Image="{}.img".format(s[0])
  ImagePath="/qingcloud/vm-image"
  VlanId=int(s[8])
  OSType=s[11]
  out=int(s[12])

  if out == 1:
    cmd.append(1)

  cmd.append("qm create {} --name {} --memory {} --cores {} --net0 virtio={},bridge={},tag={} --onboot 1 --agent 1".format(VMId,VMName,Mem,CPU,MAC,Bridge,VlanId))
  cmd.append("qm importdisk {} /qingcloud/vm-image/{} {}".format(VMId,Image,Storage))
  cmd.append("qm set {} --scsihw virtio-scsi-pci --scsi0 {}:vm-{}-disk-0".format(VMId,Storage,VMId))
  cmd.append("qm set {} --boot c --bootdisk scsi0".format(VMId))
  if OSType == "linux":
    cmd.append("qm set {} --ide2 {}:cloudinit".format(VMId,Storage))
    cmd.append("qm set {} --ciuser=root".format(VMId))
    cmd.append("qm set {} --cipassword=pSEqXW5AOyJReBVY".format(VMId))
    cmd.append("qm set {} --serial0 socket --vga serial0".format(VMId))
  else:
    cmd.append("qm set {} --vga std".format(VMId))


for i in range(len(cmd)):
  if cmd[0] == 1:
    print(cmd[i])

