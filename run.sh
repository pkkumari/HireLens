#!/bin/bash
# Helper script to run npm commands with nvm loaded

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use --lts

# Run the command passed as arguments
"$@"

