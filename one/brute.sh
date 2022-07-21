#!/bin/bash



i=0
while read line
do
   echo "Testing ${line}"
   echo -e "${i}\n"
   
   echo -n $( gpg --batch --passphrase ${line} $2 )
   
   let i=i+1
done < $1
