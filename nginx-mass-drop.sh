#!/bin/bash
# riesal[at]gmail[dot]com
# block an IP if it had greater than 6 concurrent request per second

tail -n 1000 /var/log/nginx/access.log | grep $(date +%d/%b/%Y:%H:%M:$(($(date +%S)-1))) | awk '{print $2}' | sort -n | uniq -c | awk '{print $1,$2}' | sort -n > /tmp/blokir.log

while read line; 
do 
  set $line
  if [[ $1 -gt 6 ]]; then 
    echo $1 $2
    iptables -A INPUT -s $2 -j DROP
  fi
done < /tmp/blokir.log
