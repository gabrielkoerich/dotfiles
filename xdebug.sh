# Install Xdebug -> https://xdebug.org/wizard.php
mkdir -p ~/Projects && cd ~/Projects
wget -qO- http://xdebug.org/files/xdebug-2.6.1.tgz | tar -xvz
cd xdebug-2.6.1 && phpize && ./configure && make
cp modules/xdebug.so "$(php-config --extension-dir)"/xdebug.so
rm -Rf ~/Projects/xdebug-2.6.1