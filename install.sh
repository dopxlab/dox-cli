#!/bin/bash

set -e

#PRE-REQUEST: List of required tools
REQUIRED_TOOLS=("tar" "unzip" "curl")
MISSING_TOOLS=()

# Check if each required tool is installed
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    MISSING_TOOLS+=("$tool")
  fi
done

# If there are missing tools, print the message
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
  echo "Note:"
  echo "The following required tools are missing: ${MISSING_TOOLS[*]}"
  echo "To install them, run the following command:"
  echo
  echo "  sudo apt update && sudo apt install -y ${MISSING_TOOLS[*]}"
  echo
  echo "This will update your package lists and install the missing tools."
else
  echo "All required tools are already installed."
fi


# INSTALLATION 
export DOX_DIR="$HOME/.dox"

# Define the URL for the latest release tarball and the install directory
DOX_RELEASE_URL="https://github.com/dopxlab/dox-cli/releases/latest/download/dox-cli.tar.gz"

mkdir -p "$DOX_DIR"

# Download, extract, and set up DOX CLI
curl -LO $DOX_RELEASE_URL && tar -xzf dox-cli.tar.gz -C "$DOX_DIR" && rm -f dox-cli.tar.gz

# Link DOX to user bin
ln -sf "$DOX_DIR/bin/dox" "$LOCAL_BIN/dox"
chmod +x "$DOX_DIR/bin/dox"

chmod -R 755 $DOX_DIR

# Check if yq is installed, if not, install it
command -v yq &>/dev/null || {
  curl -sL https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64.tar.gz -o yq_linux_amd64.tar.gz
  mkdir -p yq && tar -xzvf yq_linux_amd64.tar.gz -C yq
  mv yq/yq_linux_amd64 "$DOX_DIR/bin/yq"
  chmod +x "$DOX_DIR/bin/yq"
  ln -sf "$DOX_DIR/bin/yq" "$LOCAL_BIN/yq"
  rm -rf yq_linux_amd64.tar.gz yq
  echo "✅ yq installed successfully."
}

echo "✅ DOX CLI installed successfully!"
