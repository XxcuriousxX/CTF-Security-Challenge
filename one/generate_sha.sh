#!/bin/bash 

rm keys;
touch keys;

for each in ${*}
do

for i in {1..365};do
    # ISO 8601 (e.g. 2020-02-20) using -I
    ready=$(date -I -d "2021-01-01 +$i days")
    check="${ready} ${each}"    
    test=$(echo -n $check | sha256sum | tr -d ' -' >> keys)
    
done
done

