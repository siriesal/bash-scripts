#!/bin/bash
# riesal@gmail.com
# usage: $ bash bash-csv-parser.sh servers.csv result.txt

input=$1
output=$2

# use ";" as the field separator using $IFS 
# and read line by line using while read combo 

while IFS=';' read -r f1 f2 f3 f4 f5 f6 f7
do
  echo "$f1 $f2 $f3 $f4 $f5 $f6 $f7" >> text.txt
done < "$input"

awk '{print $2}' text.txt | cut -d'"' -f2 > $output
rm text.txt
