# echo "Loading .zprofile"

export NVM_DIR="$HOME/.nvm"

# Fix for Sublime LSP
export PATH="$PATH:$NVM_DIR/versions/node/v20.8.0/bin"

unsetopt HIST_VERIFY
