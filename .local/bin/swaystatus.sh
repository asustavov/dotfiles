#!/usr/bin/bash
while 

bp=$(acpi -b | awk -F', ' '{print substr($2, 1, length($2)-1) }')

#using fontawesone, unicode f240 to f244 
echo -e "\uf24$(((110 - $bp) / 25)) $bp% $(date +'%H:%M')"

do sleep 20
done
