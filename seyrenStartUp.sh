#!/bin/bash
pushd /opt/seyren &> /dev/null

# export environmet
export GRAPHITE_URL="http://your-graphite-web-url"
export SMTP_HOST="localhost"
export SMTP_FROM="seyren@your-seyren-url"
export SEYREN_URL="http://your-seyren-url"
export PUSHOVER_APP_API_TOKEN="your-pushover-token"

# setting locale
export LANG=C
export LC_ALL=C
export LC_MESSAGES=C

http="8000"

function mulai {
    echo "Bersiap menyalakan java untuk Seyren.."
    nohup java -Xms6144M -Xmx6144M -XX:PermSize=1024m -XX:MaxPermSize=1024m -XX:+CMSPermGenSweepingEnabled -XX:+CMSClassUnloadingEnabled -XX:+HeapDumpOnOutOfMemoryError -XX:+PrintGCDetails -verbose:gc -XX:+PrintGCDateStamps -XX:+UseParallelOldGC -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=128K -jar seyren-1.3.0.jar -httpPort=$http &> /dev/null &
    echo "Seyren telah dijalankan dan siap digunakan.."
}

function berhenti {
    echo "Bersiap memberhentikan Seyren.."
    status=( $(for i in `ps ax |  awk '/seyren-1.3.0.jar/ && !/awk/ {print $1}'` ; do kill -9 $i; done ))
    echo "Seyren telah diberhentikan.."
}

clear

perintah=""
if [[ "$1" == "mulai" ]]; then
    perintah="mulai" &> /dev/null
    mulai
elif [[ "$1" == "berhenti" ]]; then
    perintah="berhenti"
    berhenti
else
    echo "Perintah anda tidak dikenali. Gunakan opsi mulai atau berhenti."
    if [[ $(ps ax | awk '/seyren-1.3.0.jar/' && !/awk/ {print $1}') -gt 0 ]]; then
      echo "Status: Seyren sedang beroperasi."
    else
      echo "Status: Seyren sedang berhenti."
fi

popd &> /dev/null
