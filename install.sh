#!/bin/bash

set -e

# Define the URL for the latest release tarball and the install directory
DOX_RELEASE_URL="https://github.com/dopxlab/dox-cli/releases/latest/download/dox-cli.tar.gz"
INSTALL_DIR="$HOME/.dox"

mkdir -p "$INSTALL_DIR"

# Download, extract, and set up DOX CLI
curl -LO $DOX_RELEASE_URL && tar -xzf dox-cli.tar.gz -C "$INSTALL_DIR" && rm -f dox-cli.tar.gz

# Add the bin directory to PATH if it's not already there
grep -q "$INSTALL_DIR/bin" "$HOME/.bashrc" || echo "export PATH=\"$INSTALL_DIR/bin:\$PATH\"" >> "$HOME/.bashrc" && source "$HOME/.bashrc"

echo "✅ DOX CLI installed successfully!"
