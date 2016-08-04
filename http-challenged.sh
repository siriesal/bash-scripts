#!/bin/bash
# see if some of the sites here using reblaze to challenge requests

urls=(issta.co.il anyoption.com alljobs.co.il)

for i in "${urls[@]}"
do
  isChallenged=$(curl -i -X GET https://www.$i --silent | grep rbzns.challdomain | grep $i)
  if [[ -z $isChallenged ]]
  then
    echo "Country $i is not challenged."
  else
    echo "Country $i is challenged."
  fi
done
