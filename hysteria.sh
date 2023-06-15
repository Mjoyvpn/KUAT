#!/bin/sh

#Do not forget to set this variables
DOMAIN=udp.vpnsakir.tech
CF_ID=puasapanel@gmail.com
CF_KEY=c505716a3e602a24714e0b15cc9cc3f5c8efc
CF_ZONE=f05290122d482860a2e4e08e372ab999
SSL_ID=puasapanel@gmail.com
MYIP=$(wget -qO- icanhazip.com);
server_ip=$(curl -s https://api.ipify.org)

timedatectl set-timezone Asia/Riyadh

install_require () {
clear
echo 'Installing dependencies.'
{
export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y gnupg openssl 
apt install -y iptables socat
apt install -y netcat httpie php neofetch vnstat
apt install -y screen gnutls-bin python
apt install -y dos2unix nano unzip jq virt-what net-tools default-mysql-client
apt install -y build-essential
clear
}
clear
}

install_hysteria(){
clear
echo 'Installing hysteria.'
{
wget https://raw.githubusercontent.com/Mjoyvpn/SC/main/install_server.sh; chmod +x install_server.sh; ./install_server.sh
} 
}

modify_hysteria(){
clear
echo 'Modifying Hysteria.'
{
rm -f /etc/hysteria/config.json

echo '{
  "listen": ":1080",
  "cert": "/etc/hysteria/hysteria.crt",
  "key": "/etc/hysteria/hysteria.key",
  "up_mbps": 100,
  "down_mbps": 100,
  "disable_udp": false,
  "obfs": "agnudp",
  "auth": {
    "mode": "passwords",
    "config": ["agnudp", "agnudps"]
  }
}
' >> /etc/hysteria/config.json

chmod 755 /etc/hysteria/config.json
chmod 755 /etc/hysteria/hysteria.crt
chmod 755 /etc/hysteria/hysteria.key
}
}

install_letsencrypt()
{
clear
echo "Installing letsencrypt."
{
apt remove apache2 -y
echo "$DOMAIN" > /root/domain
domain=$(cat /root/domain)
curl  https://get.acme.sh | sh
~/.acme.sh/acme.sh --register-account -m puasapanel@gmail.com@gmail.com --server zerossl
~/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256
~/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath /etc/hysteria/hysteria.crt --keypath /etc/hysteria/hysteria.key --ecc
chmod 755 /etc/hysteria/hysteria.crt
chmod 755 755 /etc/hysteria/hysteria.key
}
}

installBBR() {
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    
    apt install -y linux-generic-hwe-20.04
    grub-set-default 0
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    INSTALL_BBR=true
}

install_firewall_kvm () {
clear
echo "Installing iptables."
sysctl -p
{

iptables -t nat -A PREROUTING -i $(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1) -p udp --dport 20000:50000 -j DNAT --to-destination :1080
ip6tables -t nat -A PREROUTING -i $(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1) -p udp --dport 20000:50000 -j DNAT --to-destination :1080

sysctl net.ipv4.conf.all.rp_filter=0 
sysctl net.ipv4.conf.eth0.rp_filter=0 

echo "net.ipv4.ip_forward = 1 
net.ipv4.conf.all.rp_filter=0 
net.ipv4.conf.eth0.rp_filter=0" > /etc/sysctl.conf 

sysctl -p 
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections 
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections 

iptables-save > /etc/iptables_rules.v4
ip6tables-save > /etc/iptables_rules.v6
}
}


install_rclocal(){
  {  
  
    echo "[Unit]
Description=firenet service
Documentation=joysmark

[Service]
Type=oneshot
ExecStart=/bin/bash /etc/rc.local
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/firenet.service
    echo '#!/bin/sh -e
iptables-restore < /etc/iptables_rules.v4
ip6tables-restore < /etc/iptables_rules.v6
sysctl -p
service hysteria-server restart
exit 0' >> /etc/rc.local
    sudo chmod +x /etc/rc.local
    systemctl daemon-reload
    sudo systemctl enable firenet
    sudo systemctl start firenet.service
  }
}

start_service () {
clear
echo 'Starting..'
{

sudo crontab -l | { echo "7 0 * * * /root/.acme.sh/acme.sh --cron --home /root/.acme.sh > /dev/null"; } | crontab -
sudo systemctl restart cron
}
clear
echo '++++++++++++++++++++++++++++++++++'
echo '*       JOYSMARK Is Ready!    *'
echo '+++++++++++************+++++++++++'
echo -e "[IP] : $server_ip\n[Joysmark Port] : 1080\n"
history -c;
echo 'Server will secure this server and reboot after 20 seconds'
sleep 20
reboot
}

install_require 
install_kibisakir
install_letsencrypt
install_firewall_kvm
modify_joysmark
installBBR
install_rclocal
start_service
