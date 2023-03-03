#!/bin/sh -e


# install packages we need (build-essential is temporary)
apt-get -y install xserver-xorg xserver-xorg-video-all \
	chromium unclutter ifplugd xinit blackbox \
	network-manager \
	nano screen ntpdate openssh-server sddm
	
# clean up apt caches
apt-get -y clean

wget https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
chmod +x setup-repos.sh
./setup-repos.sh

apt-get install webmin -y

# create a user account that, when logged in,
# will start the X server and the player
useradd -m -s `which xinit` concerto

# create a url.sh that defines the screen URL
cat > /home/concerto/url.sh << "EOF"
#!/bin/sh
URL=""

EOF

# create a .xinitrc that will start fullscreen chromium
cat > /home/concerto/.xsessionrc << "EOF"
#!/bin/sh
source url.sh

# hide the mouse pointer
unclutter &
# disable power-management and screen blanking
xset -dpms
xset s off

# run the browser (if it crashes or dies, the X session should end)
/usr/bin/chromium --noerrdialogs --disable-translate --disable-infobars --no-first-run --kiosk $URL
EOF

mkdir -p /etc/sddm.conf.d

cat > /etc/sddm.conf.d/concerto << EOF
[Autologin]
User=concerto
Session=blackbox.desktop
Relogin=false
EOF

systemctl enable sddm
