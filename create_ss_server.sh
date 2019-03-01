#!/bin/bash

####################################
conf_path="/etc/shadowsocks/" #
port=443;                        #
password="12345678"              #
encrypt="chacha20-ietf-poly1305" #
####################################

set -x

param_pwd=$1
if [ -n "$param_pwd" ];then
  password=$param_pwd
fi

systemctl stop firewalld
systemctl disable firewalld

rm -rf $conf_path
mkdir -p $conf_path

yum update -y
yum install net-tools -y
yum -y install epel-release
yum install -y python-pip git gcc gcc-c++ make
pip install --upgrade pip
pip install setuptools
# pip install shadowsocks
pip install git+https://github.com/shadowsocks/shadowsocks.git@master

cd $conf_path

cat > $conf_path/config.json <<EOF
{
    "server":"0.0.0.0",
    "server_port":$port,
    "password":"$password",
    "method":"$encrypt"
}
EOF

cd /root/
if [ ! -f libsodium-1.0.15.tar.gz ];then
	wget https://github.com/jedisct1/libsodium/releases/download/1.0.15/libsodium-1.0.15.tar.gz
	tar zxvf libsodium-1.0.15.tar.gz
	cd libsodium-1.0.15
	./configure
	make && make install 
	echo "/usr/local/lib" > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
fi

start_cmd="export LD_LIBRARY_PATH=/usr/local/lib; ssserver -c "$conf_path"config.json -d start"
export LD_LIBRARY_PATH=/usr/local/lib
/usr/bin/ssserver -c "$conf_path"config.json -d start
echo 'shadowsocks started'
#sleep 3

echo "$start_cmd" >> /etc/rc.local
chmod +x /etc/rc.d/rc.local

echo "done"
reboot
