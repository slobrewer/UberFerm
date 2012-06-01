#!/bin/sh
PATH=/opt/bin:/opt/sbin:/opt/usr/sbin:/bin:/usr/bin:/sbin:/usr/sbin:/jffs/sbin:/jffs/bin:/jffs/usr/sbin:/jffs/usr/bin:/mmc/sbin:/mmc/bin:/mmc/usr/sbin:/mmc/usr/bin
SERVICE='python'
 
if ps ax | grep -v grep | grep $SERVICE > /dev/null
then
    echo "$SERVICE service running, everything is fine"
else
    if [ ! -f /tmp/uberfridge_dontrun ];
    then
        echo "restarting uberfridge script"
        logger "Python script not found by CRON, restarting python"
	python -u /mnt/uberfridge/uberfridge.py 1>/mnt/uberfridge/stdout.txt 2>>/mnt/uberfridge/stderr.txt &
    else
	echo "dontrun file exists, not restarting"
    fi
fi
if [ ! -f /dev/usb/tts/0 ];
then
    echo "Serial port found"
else
    echo "Serial port not found, rebooting!"
    logger Serial port not found, rebooting!
    reboot
fi


# This script checks whether python the script is running. If it is not running, it starts the script.
# A dontrun file is written if the script is stopped manually, so CRON will not restart it.
# If the serial port is lost, the router reboots.
# messages are logged to dmesg