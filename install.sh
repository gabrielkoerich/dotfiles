#!/usr/bin/env bash

set -o pipefail

echo 'Starting...';

# Check to see if Homebrew is installed, and install it if it is not
command -v brew >/dev/null 2>&1 || {
    echo >&2 "Installing Homebrew"; \

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

## Add command-time plugin
git clone https://github.com/popstas/zsh-command-time.git ~/.oh-my-zsh/custom/plugins/command-time

# Install `wget` with IRI support.
brew install wget

# Install more recent versions of some macOS tools.
brew install vim
brew install grep
brew install openssh
brew install screen

# Install R and stuff
# brew install r
# Rscript -e 'install.packages("reticulate")'

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
brew install git
brew install git-extras
brew install imagemagick --with-webp
brew install p7zip
brew install speedtest-cli
brew install ssh-copy-id
brew install pandoc # convert doc files
brew install bat # better cat
brew install gh
# brew install git-town # git workflows
brew install htop
brew install mackup # app backups to cloud
brew install innotop # innodb top cmd
# brew install mycli #mysql client
# brew install mas
brew install pv # pipeviewer
brew install watch # watcher
brew install jq # json bash processor
brew install neofetch # Awesome system info
# brew install utm # VM for M1
# brew install fastlane #build ios apps
# brew install cocoapods #ios dependencies
# brew tap AlexanderWillner/tap
# brew install things.sh
brew install just # Just command runner
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
brew install maclaunch # Check launch agents

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

# Remove outdated versions from the cellar.
brew cleanup
brew doctor

# List services to check them
brew services list
