#!/bin/bash
# ########################### ATENCAO! ################################
#
#       O padrao desse firewall eh bloquear todo acesso internacional
#    com  destino ao servidor (UDP/5060).  Hosts  internacionais  com
#    permissao para UDP/5060 devem estar setados na variavel ACC_SIP.
#
#       Hosts nacionais que devem ser negados para UDP/5060 devem ser
#    setados na variavel NO_SIP.
#
#######################################################################
#
# 09/2011 - Thiago Jose Lucas | thiagojlucas@gmail.com
#
####
# CONSTANTES
LACNIC_FTP_FILE='ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest'
LACNIC_FILE='/tmp/delegated-lacnic-latest'
PARSE_SCRIPT='/etc/parse.py' # CAMINHO COMPLETO
IPT='/sbin/iptables'
CHAIN_NAME='SIP'
SIP_PORT='5060'
MAIL_CMD='sendEmail'
WGET_TIMEOUT='14'
# HOSTS LIBERADOS PARA SIP
# (separado por espaco)
ACC_SIP='192.168.10.0/24 192.168.1.0/24 192.168.0.0/24 172.30.10.0 191.209.125.144'
NO_SIP=''

# COMANDO BASICOS NECESSARIOS
basic(){
  echo "Erro: Favor instalar o comando $1 antes de executar este script!"
  exit 0
}

BASIC_CMD="host iptables echo wget hostname ip $MAIL_CMD"
for CMD in $BASIC_CMD ;do
  which $CMD >/dev/null 2> /dev/null || basic $CMD
done

nameTest(){
  host ftp.lacnic.net > /dev/null || alert "Problema na resolucao de nomes - (DNS)"
}

alert(){
OPT=$1
IP_ADDRESS=`ip r g 200.192.243.50|head -n1|awk '{print $7}'`
MY_HOSTNAME='Ibinetwork Informática'
MAIL_FROM=''
MAIL_TO=''
MAIL_SUBJECT='SIPFirewall - Problema na Execucao'
MAIL_SERVER_SMTP=''
MAIL_USER_SMTP=''
MAIL_PASS_SMTP=''
MAIL_BODY="
Erro ao executar $0:
$OPT

Hostname: $MY_HOSTNAME
IP Address: $IP_ADDRESS

Atenciosamente
--
NOC Ibinetwork Informatica
suporte@ibinetwork.com.br
www.ibinetwork.com.br
55.11.3042.1234
"

$MAIL_CMD -f "$MAIL_FROM" -t "$MAIL_TO" -u "$MAIL_SUBJECT" -s "$MAIL_SERVER_SMTP" -xu "$MAIL_USER_SMTP" -xp "$MAIL_PASS_SMTP" -m "$MAIL_BODY"
}

# TESTA A EXISTENCIA E O PERMISSIONAMENTO DE $PARSE_SCRIPT
[ -e "$PARSE_SCRIPT" -o -x "$PARSE_SCRIPT" ] || alert "Problema ao chamar $PARSE_SCRIPT"

get(){
  wget -q -O $LACNIC_FILE $LACNIC_FTP_FILE -T $WGET_TIMEOUT|| alert "Erro ao baixar o Arquivo - (wget)"
}

parse(){
  $PARSE_SCRIPT $LACNIC_FILE
}

nameTest
get

# TRATA A CHAIN A SER UTILIZADA #
$IPT -t mangle -D PREROUTING -p UDP --dport $SIP_PORT -j $CHAIN_NAME 2>/dev/null
$IPT -t mangle -F $CHAIN_NAME 2>/dev/null
$IPT -t mangle -X $CHAIN_NAME 2>/dev/null
$IPT -t mangle -N $CHAIN_NAME 2>/dev/null

# DROP P/ TRAFEGO UDP/5060 - $CHAIN_NAME
$IPT -t mangle -I $CHAIN_NAME -p UDP --dport $SIP_PORT -j DROP

# ACCEPT P/ REDES DO BRASIL
parse|while read NETWORK ;do
  $IPT -t mangle -I $CHAIN_NAME -p UDP -s $NETWORK --dport $SIP_PORT -j ACCEPT
done

# ACCEPT PARA REDES SETADAS EM ACC_SIP
if [ ! -z "$ACC_SIP" ] ;then
  for _HOST in $ACC_SIP ;do
    $IPT -t mangle -I $CHAIN_NAME -p UDP -s $_HOST --dport $SIP_PORT -j ACCEPT
  done
fi

# DROP PARA REDES SETADAS EM NO_SIP
if [ ! -z "$NO_SIP" ] ;then
  for _HOST in $NO_SIP ;do
    $IPT -t mangle -I $CHAIN_NAME -p UDP -s $_HOST --dport $SIP_PORT -j DROP
  done
fi

# REDIR. DE TRAFEGO PARA $CHAIN_NAME
$IPT -t mangle -I PREROUTING -p UDP --dport $SIP_PORT -j $CHAIN_NAME
