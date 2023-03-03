#!/bin/sh -e


# install packages we need (build-essential is temporary)
apt-get -y install xserver-xorg xserver-xorg-video-all \
	chromium unclutter ifplugd xinit blackbox \
	network-manager \
	nano screen ntpdate openssh-server sddm
	
# clean up apt caches
apt-get -y clean

# shellcheck disable=SC1090 disable=SC2059 disable=SC2164 disable=SC2181
# setup-repos.sh
# Configures Webmin repository for RHEL and Debian systems (derivatives)

webmin_download="https://download.webmin.com"
webmin_key="jcameron-key.asc"
webmin_key_download="$webmin_download/$webmin_key"
debian_repo_file="/etc/apt/sources.list.d/webmin.list"
rhel_repo_file="/etc/yum.repos.d/webmin.repo"
download_wget="/usr/bin/wget"
download="$download_wget -nv"

# Temporary colors
NORMAL=''
GREEN=''
RED=''
ITALIC=''
BOLD=''
if tty -s; then
  NORMAL="$(tput sgr0)"
  GREEN=$(tput setaf 2)
  RED="$(tput setaf 1)"
  BOLD=$(tput bold)
  ITALIC=$(tput sitm)
fi

# Check user permission
if [ "$(id -u)" -ne 0 ]; then
    echo "${RED}Error:${NORMAL} \`setup-repos.sh\` script must be run as root!" >&2
    exit 1
fi

# Go to temp
cd "/tmp" 1>/dev/null 2>&1
if [ "$?" != "0" ]; then
  echo "${RED}Error:${NORMAL} Failed to switch to \`/tmp\` directory!"
  exit 1
fi

# Check for OS release file
osrelease="/etc/os-release"
if [ ! -f "$osrelease" ]; then
  echo "${RED}Error:${NORMAL} Cannot detect OS!"
  exit 1
fi

# Detect OS and package manager and install command
. "$osrelease"
if [ -n "${ID_LIKE}" ]; then
    osid="$ID_LIKE"
else
    osid="$ID"
fi
if [ -z "$osid" ]; then
  echo "${RED}Error:${NORMAL} Failed to detect OS!"
  exit 1
fi

# Derivatives precise test
osid_debian_like=$(echo "$osid" | grep "debian\|ubuntu")
osid_rhel_like=$(echo "$osid" | grep "rhel\|fedora\|centos")

# Setup OS dependent
if [ -n "$osid_debian_like" ]; then
  package_type=deb
  install_cmd="apt-get install"
  install="$install_cmd --quiet --assume-yes"
  clean="apt-get clean"
  update="apt-get update"
elif [ -n "$osid_rhel_like" ]; then
  package_type=rpm
  if command -pv dnf 1>/dev/null 2>&1; then
    install_cmd="dnf install"
    install="$install_cmd -y"
    clean="dnf clean all"
  else
    install_cmd="yum install"
    install="$install_cmd -y"
    clean="yum clean all"
  fi
else
  echo "${RED}Error:${NORMAL} Unknown OS : $osid"
  exit
fi

# Check for wget or curl or fetch
if [ ! -x "$download_wget" ]; then
  if [ -x "/usr/bin/curl" ]; then
    download="/usr/bin/curl -f -s -L -O"
  elif [ -x "/usr/bin/fetch" ]; then
    download="/usr/bin/fetch"
  else
    # Try installing wget
    echo "  Installing required ${ITALIC}wget${NORMAL} package from OS repository .."
    $install wget 1>/dev/null 2>&1
    if [ "$?" != "0" ]; then
      echo "  .. failed to install 'wget' package!"
      exit 1
    else
      echo "  .. done"
    fi
  fi
fi


# Check if GPG command is installed
if [ -n "$osid_debian_like" ]; then
  if [ ! -x /usr/bin/gpg ]; then
    $update 1>/dev/null 2>&1
    $install gnupg 1>/dev/null 2>&1
  fi
fi

# Clean files
rm -f "/tmp/$webmin_key"

# Download key
echo "  Downloading Webmin key .."
download_out=$($download $webmin_key_download 2>/dev/null 2>&1)
if [ "$?" != "0" ]; then
  download_out=$(echo "$download_out" | tr '\n' ' ')
  echo "  ..failed : $download_out"
  exit
else
  echo "  .. done"
fi

# Setup repos
case "$package_type" in
rpm)
  # Install our keys
  echo "  Installing Webmin key .."
  rpm --import $webmin_key
  cp -f $webmin_key /etc/pki/rpm-gpg/RPM-GPG-KEY-webmin
  echo "  .. done"
  # Create repo file
  echo "  Setting up Webmin repository .."
  echo "[webmin-noarch]" >$rhel_repo_file
  echo "name=Webmin - noarch" >>$rhel_repo_file
  echo "baseurl=$webmin_download/download/yum" >>$rhel_repo_file
  echo "enabled=1" >>$rhel_repo_file
  echo "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-webmin" >>$rhel_repo_file
  echo "gpgcheck=1" >>$rhel_repo_file
  echo "  .. done"
  # Clean meta
  echo "  Cleaning repository metadata .."
  $clean 1>/dev/null 2>&1
  echo "  .. done"
  ;;
deb)
  # Install our keys
  echo "  Installing Webmin key .."
  gpg --import $webmin_key 1>/dev/null 2>&1
  cat $webmin_key | gpg --dearmor > /usr/share/keyrings/debian-webmin.gpg
  echo "  .. done"
  # Create repo file
  echo "  Setting up Webmin repository .."
  echo "deb [signed-by=/usr/share/keyrings/debian-webmin.gpg] $webmin_download/download/repository sarge contrib" >$debian_repo_file
  echo "  .. done"
  # Clean meta
  echo "  Cleaning repository metadata .."
  $clean 1>/dev/null 2>&1
  echo "  .. done"
  # Update meta
  echo "  Downloading repository metadata .."
  $update 1>/dev/null 2>&1
  echo "  .. done"
  ;;
*)
  echo "${RED}Error:${NORMAL} Cannot setup repositories on this system."
  exit 1
  ;;
esac

# Could not setup
if [ ! -x "/usr/bin/webmin" ]; then
  echo "Webmin package can now be installed using ${GREEN}${BOLD}${ITALIC}$install_cmd webmin${NORMAL} command."
fi

exit 0

apt-get install webmin -y

# create a user account that, when logged in,
# will start the X server and the player
useradd -m -s `which xinit` concerto

EOF

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
Session=blackbox.desktop
Relogin=false
EOF

systemctl enable sddm
