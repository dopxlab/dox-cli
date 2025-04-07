#!/bin/bash

set -e

export DOX_DIR="$HOME/lib/dox"

# Define the URL for the latest release tarball and the install directory
DOX_RELEASE_URL="https://github.com/dopxlab/dox-cli/releases/latest/download/dox-cli.tar.gz"

mkdir -p "$DOX_DIR"

# Download, extract, and set up DOX CLI
curl -LO $DOX_RELEASE_URL && tar -xzf dox-cli.tar.gz -C "$DOX_DIR" && rm -f dox-cli.tar.gz

# Add the bin directory to PATH if it's not already there
grep -q "$DOX_DIR/bin" "$HOME/.bashrc" || echo "export PATH=\"$DOX_DIR/bin:\$PATH\"" >> "$HOME/.bashrc" && source "$HOME/.bashrc"

echo "✅ DOX CLI installed successfully!"
