#!/bin/bash


echo -e "$# args given"

#curl http://169.254.169.254/latest/meta-data

curl_uri='http://169.254.169.254/latest/meta-data'

for var in "$@" ; do curl_uri+="/$var";done

if [ "$#" -eq "0" ]; then
   curl_uri+='/';
fi

echo -e " Running curl uri \n\t$curl_uri\n"
echo -e "If nothign returned may need to append '/' to arg\n"
echo -e "RESULT:"
echo -e "-------\n"

curl -s $curl_uri

echo -e  "\n"
