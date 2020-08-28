#!/usr/bin/bash
while 

#using fontawesone, unicode f240 to f244 
echo "$(acpi -b | awk -F', ' '{a=substr($2,1,length($2)-1); b=((110-a)/25+0xf240); printf("%lc %d%", b, a) }') $(date +'%H:%M')"

do sleep 20
done
