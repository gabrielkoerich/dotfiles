#!/usr/bin/env bash

# On Linux the shell is bash, and the default ~/.bashrc sources ~/.bash_aliases
# when it exists. This mirrors the dotfile loop in .zshrc so a bash machine gets
# the same path, exports, aliases and functions. Inert on macOS, where zsh runs.
#
# * ~/.extra can be used for settings you don't want to commit.

for file in ~/.{path,exports,aliases,functions,extra,private}; do
    [ -r "$file" ] && [ -f "$file" ] && . "$file"
done
unset file

# zsh dedupes $PATH with `typeset -U path PATH`, bash has no equivalent: strip
# duplicates so a nested shell re-sourcing ~/.path cannot grow PATH forever.
PATH="$(printf '%s' "$PATH" | awk -v RS=: -v ORS=: '!seen[$0]++' | sed 's/:$//')"
export PATH
