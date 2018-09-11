#!/usr/bin/env bash

# Install brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install command-line tools using Homebrew.

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade --all

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed --with-default-names

# Install zsh and oh-my-zsh
brew install zsh
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
# Note: don’t forget to add `/usr/local/bin/zsh` to `/etc/shells` before
# running `chsh`.

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# jcl theme
wget https://raw.github.com/jasonlewis/jcl-zsh-theme/master/jcl.zsh-theme
mv jcl.zsh-theme ~/.oh-my-zsh/themes/jcl.zsh-theme

# Install `wget` with IRI support.
brew install wget --with-iri

# Install more recent versions of some macOS tools.
brew install vim --override-system-vi
brew install homebrew/dupes/grep
brew install homebrew/dupes/openssh
brew install homebrew/dupes/screen

# Install PHP, MySQL, redis and beanstalkd
brew install php72
brew install php-cs-fixer
brew install mysql
brew install redis
brew install beanstalkd

# Install Python and usefull stuff
brew install pkg-config libffi openssl python
env LDFLAGS="-L$(brew --prefix openssl)/lib" CFLAGS="-I$(brew --prefix openssl)/include" pip install cryptography==1.9

# Install node, npm, yarn, gulp and grunt
brew install node
brew postinstall node
npm -g install yarn
# npm -g install gulp
# npm -g install grunt-cli

# Launch Redis on mac starts
ln -sfv /usr/local/opt/redis/*.plist ~/Library/LaunchAgents

# Install font tools.
brew tap bramstein/webfonttools
brew install sfnt2woff
brew install sfnt2woff-zopfli
brew install woff2

# Install some CTF tools; see https://github.com/ctfs/write-ups.
# brew install aircrack-ng
# brew install bfg
# brew install binutils
# brew install binwalk
# brew install cifer
# brew install dex2jar
# brew install dns2tcp
# brew install fcrackzip
# brew install foremost
# brew install hashpump
# brew install hydra
# brew install john
# brew install knock
# brew install netpbm
# brew install nmap
# brew install pngcheck
# brew install socat
# brew install sqlmap
# brew install tcpflow
# brew install tcpreplay
# brew install tcptrace
# brew install ucspi-tcp # `tcpserver` etc.
# brew install xpdf
# brew install xz

# Install other useful binaries.
brew install ack
brew install dark-mode
brew install git
brew install git-extras
brew install imagemagick --with-webp
brew install p7zip
brew install speedtest-cli
brew install ssh-copy-id
brew install tmux
brew install pandoc # convert doc files
brew install ghi
brew install hub
#brew tap git-time-metric/gtm
#brew install gtm
# brew install testssl
# brew install git-lfs
# brew install lua
# brew install lynx
# brew install pigz
# brew install pv
# brew install rename
# brew install tree
# brew install vbindiff
# brew install webkit2png
# brew install zopfli

# Install brew cask and other apps
brew tap phinze/homebrew-cask
brew install brew-cask
brew cask install alfred
brew cask install iterm2
brew cask install caffeine
brew cask install spectacle
brew cask install imageoptim
brew cask install dropbox
# brew cask install skype
brew cask install sequel-pro
# brew cask install rescuetime
brew cask install sublime-text
brew cask install the-unarchiver
brew cask install java
brew cask install flux
# brew cask install flycut
brew cask install qlmarkdown # Add quicklook view for markdown files
#brew cask install 0ad
#brew cask install slack
# brew cask install docker
#brew cask install google-chrome

# Add sublime command
ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/sublime

# Remove outdated versions from the cellar.
brew cleanup & brew prune

# Install composer 
curl -sS https://getcomposer.org/installer | php

sudo mv composer.phar /usr/local/bin/composer

composer global require laravel/valet
composer global require laravel/installer
composer global require phpunit/phpunit

~/.composer/vendor/bin/valet install

sh fonts.sh

# Install Xdebug -> https://xdebug.org/wizard.php
cd ~/Projects
wget http://xdebug.org/files/xdebug-2.6.0.tgz
tar -xvzf xdebug-2.6.0.tgz
cd xdebug-2.6.0
phpize 
./configure
make
cp modules/xdebug.so /usr/local/lib/php/pecl/20170718/xdebug.so
cp modules/xdebug.so /usr/local/lib/php/20170718/xdebug.so
