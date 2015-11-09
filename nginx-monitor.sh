#!/bin/bash
# by riesal@gmail.com

GHOST="graphite.yourdomain.name"
HOSTNAME="${COLLECTD_HOSTNAME:-`hostname -s`}"
KIRIM="pync.py $GHOST 2003"

export LANG=C
export LC_ALL=C
export LC_MESSAGES=C


function httpLatency {
  upstreamResponse=$(LC_ALL=C tail -n 1 /var/log/nginx/access.log | grep $(date +%d/%b/%Y:%H:%M:$(($(date +%S)-1))) \
  | awk '{ print $(NF) }' | grep -v -)

  if echo $upstreamResponse | grep -E ^\-?[0]?\.?[0-9]+$; then
    msec=$(echo $upstreamResponse | cut -d'.' -f2)
    echo "nginx.${HOSTNAME}.upstreamResponse $msec $(date +%s)" | $KIRIM
  else
    msec=$(($(echo "$upstreamResponse * 1000"|bc|cut -d'.' -f1)))
    echo "nginx.${HOSTNAME}.upstreamResponse $msec $(date +%s)" | $KIRIM
  fi  
}

function loadBalance {
if [[ $(hostname -s) =~ 'lb0' ]]; then
  LC_ALL=C tail -n 1000 /var/log/nginx/access.log | egrep $(date +%d/%b/%Y:%H:%M:$(($(date +%S)-1))) | \
  awk '$9 ~ /(200|301|303|400|403|404|429|495|499|500$|501$|502$|503$|504$|508$)/ {print $9}'  > /tmp/nginx.logs
  for logs in {200,301,303,400,403,404,429,495,499,500,501,502,503,504,508}
  do
    logValue=$(grep "$logs" /tmp/nginx.logs -c)
    echo "nginx.${HOSTNAME}.$logs $logValue $(date +%s)" | $KIRIM
  done
else
  LC_ALL=C tail -n 1000 /var/log/nginx/access.log | egrep $(date +%d/%b/%Y:%H:%M:$(($(date +%S)-1))) | \
  awk '$8 ~ /(200|301|303|400|403|404|429|495|499|500$|501$|502$|503$|504$|508$)/ {print $8}'  > /tmp/nginx.logs
  for logs in {200,301,303,400,403,404,429,495,499,500,501,502,503,504,508}
  do
    logValue=$(grep "$logs" /tmp/nginx.logs -c)
    echo "nginx.${HOSTNAME}.$logs $logValue $(date +%s)" | $KIRIM
  done
fi
}
unction errorCount {
  countNow=$(LC_ALL=C tail -n 1000 /var/log/nginx/error.log | grep $(date +%Y/%m/%d) | grep \
  $(date +%H:%M:$(($(date +%S)-1))) -c)
  echo "nginx.${HOSTNAME}.rawError $countNow $(date +%s)" | $KIRIM
}

while true; do
  (loadBalance &> /dev/null) && (errorCount &> /dev/null) && (httpLatency &> /dev/null)
  sleep 1
done
