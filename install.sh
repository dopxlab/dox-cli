#!/bin/bash

set -e

export DOX_DIR="$HOME/.dox"

# Define the URL for the latest release tarball and the install directory
DOX_RELEASE_URL="https://github.com/dopxlab/dox-cli/releases/latest/download/dox-cli.tar.gz"

mkdir -p "$DOX_DIR"

# Download, extract, and set up DOX CLI
curl -LO $DOX_RELEASE_URL && tar -xzf dox-cli.tar.gz -C "$DOX_DIR" && rm -f dox-cli.tar.gz

# Add the bin directory to PATH if it's not already there
grep -q "$DOX_DIR/bin" "$HOME/.bashrc" || echo "export PATH=\"$DOX_DIR/bin:\$PATH\"" >> "$HOME/.bashrc" && source "$HOME/.bashrc"

chmod -R 755 $DOX_DIR

# Check if yq is installed, if not, install it
command -v yq &>/dev/null || {
  curl -sL https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64.tar.gz -o yq_linux_amd64.tar.gz
  mkdir -p yq && tar -xzvf yq_linux_amd64.tar.gz -C yq
  mv yq/yq_linux_amd64 "$DOX_DIR/bin/yq"
  chmod +x "$DOX_DIR/bin/yq"
  rm -rf yq_linux_amd64.tar.gz yq
  echo "yq installed successfully."
}

echo "✅ DOX CLI installed successfully!"
