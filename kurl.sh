#!/bin/bash
#
# add the following format/properties while using curl to get detail FTTB:
# - namelookup time
# - connect time
# - appconnect time
# - pretransfer time
# - redirect time
# - starttransfer time
#
# riesal@gmail.com

set -o errexit
kurl=$(which curl)
curl_properties='{
 "time_namelookup": %{time_namelookup},
 "time_connect": %{time_connect},
 "time_appconnect": %{time_appconnect},
 "time_pretransfer": %{time_pretransfer},
 "time_redirect": %{time_redirect},
 "time_starttransfer": %{time_starttransfer},
 "time_total": %{time_total}
}'

exec $kurl -w "$curl_properties" -o /dev/null -s "$@"
