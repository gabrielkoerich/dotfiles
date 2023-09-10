echo "Loading .zprofile"

export NVM_DIR="$HOME/.nvm"

# Fix for Sublime LSP
export PATH="$PATH:$NVM_DIR/versions/node/v19.8.1/bin"

unsetopt HIST_VERIFY
