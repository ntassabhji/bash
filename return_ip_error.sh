#!/bin/bash


cat /var/www/42cloud.universum.com/log/error.log > all_error_1

cat all_error_1 | grep -v AH01797 | grep -v AH02032 > all_error

grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" all_error | sort > list_full
cat list_full | sort | uniq > list_uniq

for i in $(cat list_uniq)
do
echo $i $(grep $i -c list_full) >> results
sort -n -k 2 results | uniq > results.2

done


cat results.2 | while read -r _IP _COUNT
do
if [ $_COUNT -gt 20 ]
then
        echo $_IP "     " $_COUNT "     "  $(geoiplookup $_IP |  grep "GeoIP Country Edition:" | awk -F: '{ print $2}' )
fi


done