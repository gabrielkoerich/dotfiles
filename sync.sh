#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

function sync() {
    rsync --exclude ".git/" \
        --exclude ".DS_Store" \
        --exclude ".osx" \
        --exclude "bootstrap.sh" \
        --exclude "install.sh" \
        --exclude "sync.sh" \
        --exclude "README.md" \
        --exclude "LICENSE-MIT.txt" \
        --exclude "sublime-packages/" \
        -avh --no-perms . ~;
}

read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;

echo "";

if [[ $REPLY =~ ^[Yy]$ ]]; then
    sync;
fi;

unset sync;