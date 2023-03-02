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
