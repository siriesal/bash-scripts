#!/bin/bash
# riesal@gmail.com
# uneffective yet unoptimized bash script

hostname=$1
ip=$2

function addRecord {
icurl https://www.cloudflare.com/api_json.html \
-d 'a=rec_new' \
-d 'tkn=yourAPIkey' \
-d 'email=your@email.xom' \
-d 'z=yourExistingDomain.xom' \
-d 'type=A' \
-d 'name='$arecords \
-d 'content='$ip \
-d 'ttl=300'
}

for arecords in api-staging$num asset-staging$num hnetapi-staging$num hnetasset-staging$num hnet-staging$num hnetstatic-staging$num m-staging$num 
 paymentasset-staging$num payment-staging$num staging$num static-staging$num tapasset-staging$num tap-staging$num www-staging$num
do
 addRecord
done
