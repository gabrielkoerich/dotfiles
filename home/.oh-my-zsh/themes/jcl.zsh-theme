# This theme was loosely based on the theme "ys". To install, please
# refer to the README.md file.

function box_name {
    [ -f ~/.box-name ] && cat ~/.box-name || hostname -s
}

# Directory info.
local current_dir='${PWD/#$HOME/~}'

# Git info.
local git_info='$(git_prompt_info)'
ZSH_THEME_GIT_PROMPT_PREFIX=" %{$terminfo[bold]$fg[white]%}git:%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}*"
ZSH_THEME_GIT_PROMPT_CLEAN=""
 
PROMPT="%{$terminfo[bold]$fg[blue]%}%n\
%{$fg[white]%}@\
%{$fg[yellow]%}$(box_name) \
%{$reset_color%}in \
%{$terminfo[bold]$fg[yellow]%}${current_dir}%{$reset_color%}\
${git_info}
%{$terminfo[bold]$fg[white]%}$ %{$reset_color%}"