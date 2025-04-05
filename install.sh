#!/bin/bash

set -e

# Define the URL for the latest release tarball
DOX_RELEASE_URL="https://github.com/dopxlab/dox-cli/releases/latest/download/dox-cli.tar.gz"

# Define the installation directory
INSTALL_DIR="/usr/local/lib/dox"

# Function to install DOX CLI
install_dox() {
  echo "🔧 Installing DOX CLI..."

  # Check if the installation directory exists
  if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating installation directory: $INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR"
  fi

  # Download the latest release tarball directly into the current directory
  echo "⬇️ Downloading DOX CLI from $DOX_RELEASE_URL"
  curl -LO $DOX_RELEASE_URL

  # Extract the tarball contents into the target directory
  echo "📦 Extracting the tarball..."
  sudo tar -xzf dox-cli.tar.gz -C "$INSTALL_DIR"

  # Move the binary to /usr/local/bin
  echo "🔑 Moving dox binary to /usr/local/bin"
  sudo mv "$INSTALL_DIR/bin/dox" /usr/local/bin/dox

  # Set the correct permissions for the installed binary
  sudo chmod +x /usr/local/bin/dox

  # Clean up the tarball after extraction
  rm -f dox-cli.tar.gz

  echo "✅ DOX CLI installed successfully!"
}

# Call the install function
install_dox
