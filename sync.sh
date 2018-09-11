#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

function sync() {
    rsync --exclude ".git/" \
        --exclude ".DS_Store" \
        --exclude ".gitignore" \
        --exclude "fonts" \
        --exclude "com.googlecode.iterm2.plist" \
        --exclude "extra.sh" \
        --exclude "fonts.sh" \
        --exclude "install.sh" \
        --exclude "macos.sh" \
        --exclude "Preferences.sublime-settings" \
        --exclude "README.md" \
        --exclude "sync.sh" \
        -avh --no-perms . ~;
}

read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;

echo "";

if [[ $REPLY =~ ^[Yy]$ ]]; then
    sync;
fi;

unset sync;