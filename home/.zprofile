export NVM_DIR="$HOME/.nvm"

# Fix for Sublime LSP
export PATH="$PATH:$NVM_DIR/versions/node/v16.13.1/bin"
# ln -s /Users/gabriel/.nvm/versions/node/v16.13.1/bin/node node

[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
