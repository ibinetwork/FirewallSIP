#!/bin/bash

echo "Instalando Firewall SIP - Liberando apenas acesso IPs Brasileiros a porta 5060"

yum install dos2unix bind-utils -y

cd /usr/src
wget http://www.ibi.net.br/fw/firewall_sip.sh
chmod +x firewall_sip.sh
mv firewall_sip.sh /etc/
dos2unix /etc/firewall_sip.sh

wget http://www.ibi.net.br/fw/parse.py
chmod 755 parse.py
mv parse.py /etc/

wget http://www.ibi.net.br/fw/sendEmail
chmod +x sendEmail
mv sendEmail /bin/

echo /etc/firewall_sip.sh >> /etc/rc.local

/etc/firewall_sip.sh