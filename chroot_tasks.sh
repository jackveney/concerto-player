#!/bin/sh -e


# install packages we need (build-essential is temporary)
apt-get -y install \
	chromium unclutter ifplugd xinit \
	nano openssh-server sddm
	
# clean up apt caches
apt-get -y clean

wget https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
chmod +x setup-repos.sh
./setup-repos.sh

apt-get install webmin -y

# create a user account that, when logged in,
# will start the X server and the player
useradd -m -s `which xinit` concerto


# create a .xinitrc that will start fullscreen chromium
cat > /home/concerto/.xsessionrc << "EOF"
#!/bin/sh

#Set the URL for chrome to open
URL="https://concerto.wpctech.info/frontend/2"

# ----------- DO NOT EDIT BELOW THIS LINE ----------- #
xset s noblank
xset s off
xset -dpms

unclutter -idle 0.5 -root &

sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/$USER/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /home/$USER/.config/chromium/Default/Preferences

# run the browser (if it crashes or dies, the X session should end)
/usr/bin/chromium --noerrdialogs --disable-translate --disable-infobars --no-first-run --kiosk $URL
EOF

mkdir -p /etc/sddm.conf.d

cat > /etc/sddm.conf.d/concerto << EOF
[Autologin]
User=concerto
Session=cinnamon.desktop
Relogin=false
EOF

systemctl enable sddm
