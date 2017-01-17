#!/usr/bin/env bash

git pull origin master;

function sync() {
    rsync --exclude ".git/" \
        --exclude ".DS_Store" \
        --exclude ".osx" \
        --exclude "install.sh" \
        --exclude "sync.sh" \
        --exclude "README.md" \
        --exclude "fonts" \
        --exclude "fonts.sh" \
        --exclude "sublime-packages/" \
        --exclude "Preferences.sublime-settings" \
        --exclude "com.googlecode.iterm2.plist" \
        -avh --no-perms . ~;
}

read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;

echo "";

if [[ $REPLY =~ ^[Yy]$ ]]; then
    sync;
fi;

unset sync;