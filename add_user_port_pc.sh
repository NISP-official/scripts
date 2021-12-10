echo "新用户名：$1"
echo "新用户ssh端口号：$2"

UserName=""
IPAddress=""
SSHPort=""
LocalUserName=""
LocalScpPrivateKeyFile=""

scp -P $SSHPort \
    -i ~/keys/${LocalScpPrivateKeyFile} \
    ${UserName}@${IPAddress}:/home/${UserName}/keys/id_rsa_$1 /home/${LocalUserName}/keys/id_rsa_$1_${IPAddress}

sudo chmod 600 /home/${LocalUserName}/keys/id_rsa_$1_${IPAddress}
sudo chown ${LocalUserName} /home/${LocalUserName}/keys/id_rsa_$1_${IPAddress}

ssh -i /home/${LocalUserName}/keys/id_rsa_$1_${IPAddress} ubuntu@${IPAddress} -p $2
