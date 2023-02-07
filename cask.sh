#!/usr/bin/env bash

# Install brew cask and apps
brew install authy
brew install alfred
brew install iterm2
brew install caffeine
# brew install cakebrew
brew install dropbox
brew install discord
brew install github
brew install google-chrome
brew install imageoptim
#brew install java
# brew install postman
brew install qlmarkdown # Add quicklook view for markdown files
brew install spectacle # Window shortcuts
brew install vlc
brew install the-unarchiver
brew install sublime-text

# Install privacy utils
brew install cryptomator # Encrypt iCloud/Dropbox folders
brew install knockknock # See what's persistently installed on your Mac.
brew install blockblock # Block/notify launch agents
brew install security-growler # Notify security events
# brew install lulu # Block outgoing connections, little-snitch alternative
brew install do-not-disturb # https://objective-see.org/products/dnd.html
brew install taskexplorer
brew install onyx # https://titanium-software.fr/en/onyx.html
brew install keepassxc # https://keepassxc.org
#brew install flux
#brew install flycut
#brew install steam
#brew install keybase
#brew install kap
#brew install tunnelblick
#brew install rstudio
#brew install angry-ip-scanner
#brew install 0ad
#brew install docker
#brew install tribler # Download and watch videos

# Install apps from App Store
mas lucky Things3
# mas lucky Bear
# mas lucky Wallcat
mas lucky Dato
mas lucky Pandan
mas lucky Whatsapp
# mas lucky Slack
# mas lucky Banktivity

# Add sublime command
ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/sublime
