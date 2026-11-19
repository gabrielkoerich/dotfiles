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

# Type a folder name to cd into it, as oh-my-zsh's auto_cd does. bash 4.0 added autocd, older bash skips it
if [ -n "$BASH_VERSION" ]; then
  shopt -s autocd 2>/dev/null
fi

# Over ssh, title the pane user@host: dir so the local tmux sidebar can name it
if [ -n "$SSH_CONNECTION" ]; then
  PROMPT_COMMAND="printf '\\e]2;%s@%s: %s\\a' \"\$USER\" \"\${HOSTNAME%%.*}\" \"\${PWD/#\$HOME/~}\"${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi
