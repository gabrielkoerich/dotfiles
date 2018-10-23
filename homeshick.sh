#!/bin/bash
castles="gabrielkoerich/dotfiles"

git clone git://github.com/andsens/homeshick.git $HOME/.homesick/repos/homeshick
source $HOME/.homesick/repos/homeshick/homeshick.sh

for castle in $castles; do
    homeshick clone $castle
done