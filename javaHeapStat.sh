#!/bin/bash
# riesal@gmail.com
# show some java heap statistic

export LANG=C
export LC_ALL=C
export LC_MESSAGES=C

GHOST="your-graphite-relay-host"
HOSTNAME=$(hostname -s)

# https://github.com/riesal/python-netcat-client/blob/master/pync.py
KIRIM="pync.py $GHOST 2003"
PREV_TOTAL=0
PREV_IDLE=0

while true; do
  n=( $(for i in `ps ax |  awk '/jetty-logging/ && !/awk/ {print $1}'` ; do jstat -gccapacity $i; done ))
  drill=( $(for i in `ps ax |  awk '/jetty-logging/ && !/awk/ {print $1}'` ; do jstat -gc $i; done ))

  # count max. heap
  newGenCapacity=$(echo -en "${n[17]}" | cut -d"." -f1)
  oldGenMaxCap=$(echo -en "${n[23]}" | cut -d"." -f1)
  NGCAP=$(($newGenCapacity * 1024))
  NGMAX=$(($oldGenMaxCap * 1024))

  # count heap usage
  SSU0=$(echo -en "${drill[17]}" | cut -d"." -f1)
  SSU0=$(($SSU0 * 1024))
  SSU1=$(echo -en "${drill[18]}" | cut -d"." -f1)
  SSU1=$(($SSU1 * 1024))
  ESC=$(echo -en "${drill[19]}" | cut -d"." -f1)
  ESC=$(($ESC * 1024))
  ESU=$(echo -en "${drill[20]}" | cut -d"." -f1)
  ESU=$(($ESU * 1024))
  OSU=$(echo -en "${drill[22]}" | cut -d"." -f1)
  OSU=$(($OSU * 1024))
  OSC=$(echo -en "${drill[21]}" | cut -d"." -f1)
  OSC=$(($OSC * 1024))
  PSU=$(echo -en "${drill[24]}" | cut -d"." -f1)
  PSU=$(($PSU * 1024))
  PSC=$(echo -en "${drill[23]}" | cut -d"." -f1)
  PSC=$(($PSC * 1024))
  HEAPMAX=$(($NGMAX + $NGCAP))
  HEAPUSAGE=$(($SSU0 + $SSU1 + $ESU + $OSU + $PSU))

  if [[ $HEAPMAX -gt 0 ]]; then
    echo "system.${HOSTNAME}.javaheap_heapmaxsize $HEAPMAX $(date +%s)" | $KIRIM
    echo "system.${HOSTNAME}.javaheap_heapusage $HEAPUSAGE $(date +%s)" | $KIRIM
  else
    echo "system.${HOSTNAME}.javaheap_heapmaxsize 0 $(date +%s)" | $KIRIM
    echo "system.${HOSTNAME}.javaheap_heapusage 0 $(date +%s)" | $KIRIM
  fi
  if [[ $ESC -gt 0 ]]; then
    echo "system.${HOSTNAME}.javaheap_edenspacecurcap $ESC $(date +%s)" | $KIRIM
  else
    echo "system.${HOSTNAME}.javaheap_edenspacecurcap 0 $(date +%s)" | $KIRIM
  fi
  if [[ $ESU -gt 0 ]]; then
    echo "system.${HOSTNAME}.javaheap_edenspaceusage $ESU $(date +%s)" | $KIRIM
  else
    echo "system.${HOSTNAME}.javaheap_edenspaceusage 0 $(date +%s)" | $KIRIM
  fi
  if [[ $OSU -gt 0 ]]; then
    echo "system.${HOSTNAME}.javaheap_oldgencurcap $OSU $(date +%s)" | $KIRIM
  else
    echo "system.${HOSTNAME}.javaheap_oldgencurcap 0 $(date +%s)" | $KIRIM
  fi
  if [[ $OSC -gt 0 ]]; then
    echo "system.${HOSTNAME}.javaheap_oldgenmaxcap $OSC $(date +%s)" | $KIRIM
  else
    echo "system.${HOSTNAME}.javaheap_oldgenmaxcap 0 $(date +%s)" | $KIRIM
  fi
  if [[ $PSU -gt 0 ]]; then
    echo "system.${HOSTNAME}.javaheap_permgencurcap $PSU $(date +%s)" | $KIRIM
  else
    echo "system.${HOSTNAME}.javaheap_permgencurcap 0 $(date +%s)" | $KIRIM
  fi
  if [[ $PSC -gt 0 ]]; then
    echo "system.${HOSTNAME}.javaheap_permgenmaxcap $PSC $(date +%s)" | $KIRIM
  else
    echo "system.${HOSTNAME}.javaheap_permgenmaxcap 0 $(date +%s)" | $KIRIM
  fi

  PREV_TOTAL="$TOTAL"
  PREV_IDLE="$IDLE"

  sleep 3
done
