#!/usr/bin/bash
while 

bat=`cat /sys/class/power_supply/BAT1/capacity`
ac=`cat /sys/class/power_supply/AC/online`

#using fontawesone, unicode f240 to f244 
echo "$(echo "$bat $ac"  | awk '{b=((110-$1)/25+0xf240); if($2) printf("%lc ", 0xf0e7); printf("%lc %d%", b, $1) }') $(date +'%a %d-%b %R')"

do sleep 1
done
