#!/usr/bin/env bash

set -e

echo "📦 Installing DOX CLI..."

INSTALL_DIR="/usr/local/lib/dox"
BIN_DIR="/usr/local/bin"

sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"

echo "📁 Extracting..."
sudo tar -xzf dox-cli.tar.gz -C "$INSTALL_DIR"

echo "🔗 Linking binary..."
sudo ln -sf "$INSTALL_DIR/bin/dox" "$BIN_DIR/dox"

echo "✅ DOX installed. Run with: dox"
