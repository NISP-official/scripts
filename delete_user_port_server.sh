echo "即将删除容器 $1 相关配置，端口号 $2"

ServerUserName=""

# 删除本地保存的秘钥
rm /home/${ServerUserName}/keys/id_rsa_$1*
sudo rm /usr/local/shared-folder/keys/id_rsa_$1*

# 暂停容器
sudo lxc stop $1

# 删除容器
sudo lxc delete $1

# 删除防火墙规则
sudo ufw delete allow $2/tcp

echo "容器已经删除！"