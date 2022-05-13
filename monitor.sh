#!/bin/sh
pathLog="/root/plugin/var/tuxbox/oscam.log"
pathServer="/root/plugin/var/tuxbox/config/oscam.server"
pathOscam="/root/plugin/var/bin/oscam"
pathLogMonitor="/root/plugin/var/tuxbox/monitor.log"

#logout
exec 1>> $pathLogMonitor

while :
do

#Rows count in monitor.log
rowsCount=$(cat $pathLogMonitor | wc -l )
let rowsCount/=2

#Leave last half rows in monitor.log 
if [ $rowsCount -gt 350 ]
then
 sed -i -n "${rowsCount},$ p" $pathLogMonitor
 sleep 2
 exec 1>> $pathLogMonitor
fi

#Current date and time
date +"***********%Y-%m-%d_%H-%M-%S***********"

#Delete all trims in oscam.server
sed -i 's/ //g' $pathServer

#Find rows with labels RESERVE1, RESERVE2
reserve1Row=$(sed -n '/RESERVE1/=' $pathServer)
reserve2Row=$(sed -n '/RESERVE2/=' $pathServer)
let reserve1Row++
let reserve2Row++

#Find RESERVES status (enable=0 or enable=1)
reserve1Status=$(sed -n "${reserve1Row}p" $pathServer)
reserve2Status=$(sed -n "${reserve2Row}p" $pathServer)

#Is subscribe CWDW active?
if ! tail -n 20 $pathLog | grep "login failed for user"
then
 echo "CWDW subscribe is active"

 #Are RESERVES enabled? 
 if [[ $reserve1Status == 'enable=1' ]]; then
  echo "RESERVES are enabled, ALL RIGHT"

  #Are 10 last rows contain "RESERVE"?
   if tail -n 10 $pathLog | grep "RESERVE"
   then
    echo "10 last rows contain "RESERVE", OSCAM reboot..."
    killall oscam
    sleep 2
    $pathOscam
   fi

 else
   #RESERVES are disabled, enabling...
   echo "RESERVES are disabled, enabling and OSCAM reboot..."
   sed -i "${reserve1Row}c\enable=1" $pathServer
   sed -i "${reserve2Row}c\enable=1" $pathServer
   killall oscam
   sleep 2
   $pathOscam
 fi

else
 #Are RESERVES enable? 
 if [[ $reserve1Status == 'enable=0' ]]; then 
  echo "CWDW subscribe is NOT active, RESERVES disabled"
 else
  #CWDW subscribe is NOT active, RESERVES disabling and OSCAM reboot..."
  echo "CWDW subscribe is NOT active, RESERVES disabling and OSCAM reboot..."
  sed -i "${reserve1Row}c\enable=0" $pathServer
  sed -i "${reserve2Row}c\enable=0" $pathServer
  killall oscam
  sleep 2
  $pathOscam
 fi
fi

sleep 600

done