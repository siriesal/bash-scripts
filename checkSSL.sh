#!/bin/bash
# riesal[at]gmail[dot]com
# check SSL cert lifetime through bash script

export LANG=C
export LC_ALL=C
export LC_MESSAGES=C

GHOST="your-graphite-host"
HOSTNAME="${COLLECTD_HOSTNAME:-`hostname -s`}"
# https://github.com/riesal/python-netcat-client/blob/master/pync.py
KIRIM="pync.py $GHOST 2003"

function checkSSL {
host=$1
port=443
endDate=$(echo | openssl s_client -connect $host:443 2>/dev/null | openssl x509 -noout -enddate | cut -c10-)

if [[ -n $endDate ]]
then
  endDateSeconds=$(date '+%s' --date "$endDate")
  nowSeconds=$(date '+%s')
  secUntilExpire=$(expr $endDateSeconds - $nowSeconds)
  hoursUntilExpire=$(expr $secUntilExpire / 3600)
  daysUntilExpire=$(expr $hoursUntilExpire / 24)
  echo $daysUntilExpire
fi
}

clear

bca=`checkSSL ibank.klikbca.com`
mandiri=`checkSSL ib.bankmandiri.co.id`
commbnk=`checkSSL commaccess.commbank.co.id &> /dev/null`

echo "cert.$HOSTNAME.bca.remain $bca $(date +%s)" | $KIRIM
echo "cert.$HOSTNAME.mandiri.remain $mandiri $(date +%s)" | $KIRIM

echo "klikbca.com SSL cert expires in $bca days."
echo "bankmandiri.co.id SSL cert expires in $mandiri days."

if [[ $commabnk -gt 0 ]]; then
  echo "commbank.co.id SSL cert expires in $commbnk days."
  echo "cert.$HOSTNAME.commbnk.remain $commbnk $(date +%s)" | $KIRIM
else
  echo -e "\x1b[0;31mUnable connect to https://commbank.co.id !\x1b[0m"
fi
