#!/usr/bin/env bash

set -o pipefail

echo 'Starting...';

# Check to see if Homebrew is installed, and install it if it is not
command -v brew >/dev/null 2>&1 || {
    echo >&2 "Installing Homebrew"; \
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";
}

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed

# Install zsh
brew install zsh

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Note: don’t forget to add `/usr/local/bin/zsh` to `/etc/shells` before
# running `chsh`.
chsh -s $(which zsh)

# Install `wget` with IRI support.
brew install wget

# Install more recent versions of some macOS tools.
brew install vim
brew install grep
brew install openssh
brew install screen

# Install Python and usefull stuff
brew install pkg-config libffi openssl python
env LDFLAGS="-L$(brew --prefix openssl)/lib" CFLAGS="-I$(brew --prefix openssl)/include" pip install cryptography==1.9
pip install stronghold

# Install font tools.
brew tap bramstein/webfonttools
brew install sfnt2woff
brew install sfnt2woff-zopfli
brew install woff2

# Install some CTF tools; see https://github.com/ctfs/write-ups.
sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/local/sbin/airport
brew install aircrack-ng
brew install bfg
brew install binutils
brew install binwalk
brew install cifer
brew install dex2jar
brew install dns2tcp
brew install fcrackzip
brew install foremost
brew install hashpump
brew install hashcat
brew install hashcat-utils
brew install hydra
brew install john
brew install knock
brew install netpbm
brew install nmap
brew install ngrep
brew install pngcheck
brew install socat
brew install sqlmap
brew install tcpflow
brew install tcpreplay
brew install tcptrace
brew install ucspi-tcp # `tcpserver` etc.
brew install xpdf
brew install xz

# Install other useful binaries.
brew install ack
brew install dark-mode
brew install git
brew install git-extras
brew install imagemagick --with-webp
brew install p7zip
brew install speedtest-cli
brew install ssh-copy-id
brew install pandoc # convert doc files
brew install ghi
brew install git-town
brew install hub
brew install htop
brew install mackup
brew install innotop #innodb top cmd
brew install mycli
brew install mas
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
# brew install xpdf

# Install PHP, MySQL, redis and beanstalkd
brew install mysql@5.7 && brew link mysql@5.7 --force
brew install beanstalkd
brew install redis
brew install php@7.2

# Install Xdebug + Mongo via pecl
pecl install xdebug
pecl install mongodb

# Launch Redis on mac starts
ln -sfv /usr/local/opt/redis/*.plist ~/Library/LaunchAgents

cp ./config/php-memory-limits.ini /usr/local/etc/php/7.2/conf.d/php-memory-limits.ini

# Install node, npm, yarn, gulp and grunt
brew install node@10 && brew postinstall node@10
# Run it node postinstall fails:
# sudo chown -R $(whoami) $(brew --prefix)/*
# npm -g install yarn
# npm -g install@angular/cli
# npm -g install gulp
# npm -g install grunt-cli

# Install composer
curl -sS https://getcomposer.org/installer | php

sudo mv composer.phar /usr/local/bin/composer

composer global require laravel/valet
composer global require laravel/installer
composer global require phpunit/phpunit
composer global require friendsofphp/php-cs-fixer

~/.composer/vendor/bin/valet install

# Park valet in ~/Projects
mkdir -p ~/Projects && cd ~/Projects
~/.composer/vendor/bin/valet park

# Install and configure Tmux
brew install tmux

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install TPM plugins.
# TPM requires running tmux server, as soon as `tmux start-server` does not work
# create dump __noop session in detached mode, and kill it when plugins are installed
printf "Install TPM plugins\n"
tmux new -d -s __noop >/dev/null 2>&1 || true
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "~/.tmux/plugins"
"$HOME"/.tmux/plugins/tpm/bin/install_plugins || true
tmux kill-session -t __noop >/dev/null 2>&1 || true

# Install Fonts
cp fonts/*.ttf /Library/Fonts/ && echo "Fonts installed.";

# Remove outdated versions from the cellar.
brew cleanup
brew doctor

# List services to check them
brew services list

sh cron.sh
