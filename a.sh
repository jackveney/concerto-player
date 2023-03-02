cat > /home/concerto/.xinitrc << "EOF"
#!/bin/sh
URL=`cat /proc/cmdline | perl -ne 'print "$1\n" if /concerto.url=(\S+)/'`
if [ -z $URL ]; then
	URL=http://localhost:4567/screen
fi

# add custom xrandr commands to this file
if [ -x /lib/live/mount/medium/xrandr.sh ]; then
        /lib/live/mount/medium/xrandr.sh
fi

ROTATE=`cat /proc/cmdline | perl -ne 'print "$1\n" if /concerto.rotate=(\S+)/'`
if [ -n $ROTATE ]; then
	xrandr -o $ROTATE
fi

MAC_DETECT=`cat /proc/cmdline | perl -ne 'print "1\n" if /concerto.mac_detect/'`
if [ -n $MAC_DETECT ]; then
	MAC=`/sbin/ifconfig eth0 | perl -ne 'print "$1\n" if /(([0-9a-f]{2}:){5}[0-9a-f]{2})/'`
	URL=${URL}?mac=$MAC
fi

# start window manager
blackbox &

# hide the mouse pointer
unclutter &

# disable power-management and screen blanking
xset -dpms
xset s off

# wait until the local http server is available
until wget -q http://localhost:4567
do
  sleep 2
done

# run the browser (if it crashes or dies, the X session should end)
chromium --disable-translate --disable-infobars --no-first-run --kiosk $URL
EOF
