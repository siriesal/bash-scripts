#!/bin/bash
# riesal[at]gmail[dot]com
# check disk, cpu, and memory usage

GHOST="your-grph-relay-host"
HOSTNAME=$(hostname -s)
INTERVAL="10"
KIRIM="pync.py $GHOST 2003"

function diskUsagePercent {
  # https://github.com/riesal/golang-check-diskusage
  diskUsage=$(/usr/src/diskusage $1)
  echo "system.${HOSTNAME}.diskusage$1 $diskUsage $(date +%s)" | $KIRIM
}

PREV_TOTAL=0
PREV_IDLE=0

while true; 
do

  CPU=(`sed -n 's/^cpu\s//p' /proc/stat`)
  IDLE=${CPU[3]} # Just the idle CPU time.

  TOTAL=0
  used=0
  for VALUE in "${CPU[@]}"; do
    let "TOTAL=$TOTAL+$VALUE"
  done

  let "DIFF_IDLE=$IDLE-$PREV_IDLE"
  let "DIFF_TOTAL=$TOTAL-$PREV_TOTAL"
  let "DIFF_USAGE=(1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL+5)/10"
  total=$(($(awk '/MemTotal/ && !/Async/ {print $2}' < /proc/meminfo) / 1024))
  free=$(($(awk '/MemFree/ && !/Async/ {print $2}' < /proc/meminfo) / 1024))
  used=$(($total - $free))
  used=$(bc <<< 'scale=4;('$used' / '$total')*100' | cut -d'.' -f1)
  echo "system.$HOSTNAME.usedmem $used $(date +%s)" | $KIRIM
  echo "system.$HOSTNAME.cpu $DIFF_USAGE $(date +%s)" | $KIRIM
  for i in $(df -h | awk '/dev\// {print $6}'); do diskUsagePercent $i; done

  PREV_TOTAL="$TOTAL"
  PREV_IDLE="$IDLE"
  sleep $INTERVAL
done
