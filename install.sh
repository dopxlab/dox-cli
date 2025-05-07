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
rm -rf "$DOX_DIR" && mkdir -p "$DOX_DIR"

DOX_CLI_VERSION=${DOX_CLI_VERSION:-$(curl -s https://api.github.com/repos/dopxlab/dox-cli/releases/latest | jq -r '.tag_name')}

# Define the URL for the latest release tarball and the install directory
DOX_RELEASE_URL="https://github.com/dopxlab/dox-cli/releases/download/$DOX_CLI_VERSION/dox-cli.tar.gz"

# Download, extract, and set up DOX CLI
curl -LO $DOX_RELEASE_URL && tar -xzf dox-cli.tar.gz -C "$DOX_DIR" && rm -f dox-cli.tar.gz
#Version info is saved in version.txt
echo "The DOX CLI version is: $DOX_CLI_VERSION"
echo "$DOX_CLI_VERSION" > "$DOX_DIR/version.txt"

# Append the bin directory to PATH in .bashrc if it's not already present
if ! grep -q "$DOX_DIR/bin" "$HOME/.bashrc"; then
  echo "export PATH=\"$DOX_DIR/bin:\$PATH\"" >> "$HOME/.bashrc"
  echo "Added DOX bin to PATH in .bashrc"
fi

chmod -R 755 $DOX_DIR

# Check if yq is installed, if not, install it
command -v yq &>/dev/null || {
  curl -sL https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64.tar.gz -o yq_linux_amd64.tar.gz
  mkdir -p yq && tar -xzvf yq_linux_amd64.tar.gz -C yq
  mv yq/yq_linux_amd64 "$DOX_DIR/bin/yq"
  chmod +x "$DOX_DIR/bin/yq"
  rm -rf yq_linux_amd64.tar.gz yq
  echo "✅ yq installed successfully."
}

echo "✅ DOX CLI installed successfully!"

# Export path 
export PATH="$DOX_DIR/bin:$PATH"

# Test if DOX CLI is working
echo $PATH

echo "Testing DOX CLI" 
dox --version
