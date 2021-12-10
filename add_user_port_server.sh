echo "用户名是： "$1
echo "该用户的ssh端口是： "$2

ImageName=""
ServerUserName=""

# 从配好的镜像文件中启动新的容器
sudo lxc launch ${ImageName} $1

# 必须等待容器网络配置好，否则无法安装openssh
sleep 10

# 挂载固态硬盘
if [ ! -d /mnt/data1/${1} ] ; then
	mkdir /mnt/data1/${1}
fi
sudo lxc config device add $1 data1 disk source=/mnt/data1/${1}/ path=/mnt/data1
sudo lxc exec $1 -- sudo chown -R ubuntu /mnt/data1

if [ ! -d /mnt/data2/${1} ] ; then
        mkdir /mnt/data2/${1}
fi
sudo lxc config device add $1 data2 disk source=/mnt/data2/${1}/ path=/mnt/data2
sudo lxc exec $1 -- sudo chown -R ubuntu /mnt/data2

echo "成功挂载固态硬盘！"

# 创建存放对称秘钥的文件夹
if [ ! -d /home/${ServerUserName}/keys ] ; then
	mkdir /home/${ServerUserName}/keys
fi

if [ ! -d /usr/local/shared-folder/keys ] ; then
	sudo mkdir /usr/local/shared-folder/keys
fi

# 安装容器中的openssh
sudo lxc exec $1 -- sudo apt update
sudo lxc exec $1 -- sudo apt install -y openssh-server
sudo lxc exec $1 -- sudo service ssh start
echo "容器内的ssh服务已启动！"

# 备份原来的sshd配置
sudo lxc exec $1 -- sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# 加上写入权限
sudo lxc exec $1 -- sudo chmod a+w /etc/ssh/sshd_config

# 写入新的sshd配置
sshd_config="Port ${2}
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::
PubkeyAuthentication yes
AuthorizedKeysFile      .ssh/authorized_keys
PasswordAuthentication no
Subsystem       sftp    /usr/lib/openssh/sftp-server
AllowUsers ubuntu
UsePAM yes"

sudo lxc exec $1 -- sh -c "cat>/etc/ssh/sshd_config<<EOF
${sshd_config}
EOF"

# 恢复文件权限
sudo lxc exec $1 -- sudo chmod 644 /etc/ssh/sshd_config
echo "已生成新的sshd配置文件！"

# 在宿主机上生成rsa-2048密钥
ssh-keygen -b 2048 -t rsa -f /home/${ServerUserName}/keys/id_rsa_$1 -q -N ""
echo "新密钥已生成！"

# 把公钥拷贝到共享目录下
sudo chmod a+r /home/${ServerUserName}/keys/id_rsa_$1
sudo cp /home/${ServerUserName}/keys/id_rsa_$1.pub /usr/local/shared-folder/keys/id_rsa_$1.pub
echo "公钥已写入共享目录下！"

# 把公钥写入.ssh文件夹下
sudo lxc exec $1 -- sudo mkdir /home/ubuntu/.ssh
sudo lxc exec $1 -- sudo touch /home/ubuntu/.ssh/authorized_keys
sudo lxc exec $1 -- sudo chmod a+w /home/ubuntu/.ssh/authorized_keys
sudo lxc exec $1 -- sh -c "sudo cat /usr/local/shared-folder/keys/id_rsa_$1.pub >> /home/ubuntu/.ssh/authorized_keys"

# 恢复.ssh目录的属主和文件权限
sudo lxc exec $1 -- sudo chown -R ubuntu /home/ubuntu/.ssh
sudo lxc exec $1 -- sudo chmod 700 /home/ubuntu/.ssh
sudo lxc exec $1 -- sudo chmod 644 /home/ubuntu/.ssh/authorized_keys
echo "公钥已写入.ssh文件夹！"

# 重启ssh服务
sudo lxc exec $1 -- sudo service ssh restart

# 端口映射
sudo lxc config device add $1 port-ssh proxy listen=tcp:0.0.0.0:$2 connect=tcp:127.0.0.1:$2
echo "容器内的ssh服务和端口配置完成！"

# 开启防火墙
sudo ufw allow $2/tcp
echo "防火墙端口$2已放通！"
