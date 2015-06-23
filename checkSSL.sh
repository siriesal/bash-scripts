#!/bin/bash

export LANG=C
export LC_ALL=C
export LC_MESSAGES=C

GHOST="grphproxy.traveloka.com"
HOSTNAME="${COLLECTD_HOSTNAME:-`hostname -s`}"
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

tvlkev=`checkSSL traveloka.com`
tvlkwld=`checkSSL tap.traveloka.com`
tvstwld=`checkSSL tvasset.com &> /dev/null`

echo "cert.traveloka.ev.remain $tvlkev $(date +%s)" | $KIRIM
echo "cert.traveloka.nonev.remain $tvlkwld $(date +%s)" | $KIRIM

echo "traveloka.com expires in $tvlkev days."
echo "tap.traveloka.com expires in $tvlkwld days."

if [[ $tvstwld -gt 0 ]]; then
  echo "tvasset.com expires in $tvstwld days."
  echo "cert.tvasset.nonev.remain $tvstwld $(date +%s)" | $KIRIM
else
  echo -e "\x1b[0;31mPlease check tvasset.com SSL cert!\x1b[0m"
fi
