#!/bin/sh -e


# install packages we need (build-essential is temporary)
apt-get -y install xserver-xorg xserver-xorg-video-all \
	chromium unclutter ifplugd xinit blackbox \
	rbenv ruby-dev build-essential \
	nano screen git-core ntpdate openssh-server sddm
	
rbenv install 1.9.1-p431

# and rubygems we need
#gem install bandshell
cat > /tmp/install_bandshell.sh <<EOF
#!/bin/sh -e
cd /tmp
git clone https://github.com/concerto/bandshell.git
cd bandshell
gem build bandshell.gemspec
gem install *.gem
cd /
rm -rf /tmp/bandshell
EOF
chmod +x /tmp/install_bandshell.sh
/tmp/install_bandshell.sh

# once rubygems have been installed, build-essential isn't needed
apt-get -y purge build-essential
apt-get -y autoremove

# clean up apt caches
apt-get -y clean

# create a user account that, when logged in,
# will start the X server and the player
useradd -m -s `which xinit` concerto

# create a .xinitrc that will start fullscreen chromium
cat > /home/concerto/.xinitrc << "EOF"
#!/bin/sh
URL=`cat /proc/cmdline | perl -ne 'print "$1\n" if /concerto.url=(\S+)/'`
if [ -z $URL ]; then
	URL=http://localhost:4567/screen
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
/usr/bin/chromium-browser --noerrdialogs --disable-translate --disable-infobars --no-first-run --kiosk $URL
EOF

mkdir -p /etc/sddm.conf.d

cat > /etc/sddm.conf.d/concerto << EOF
[Autologin]
User=concerto
Session=blackbox.desktop
Relogin=false
EOF

systemctl enable sddm

# create systemctl file to start bandshell
cat > /etc/systemd/system/bandshell.service << EOF
[Unit]
Description= bandshell for concerto

[Service]
ExecStart=/bin/bash /usr/local/bin/bandshelld start

[Install]
WantedBy= multi-user.target
EOF

systemctl enable bandshell.service
