#!/bin/bash

set -e

# Check if DOX is already installed
if command -v dox &>/dev/null; then
  INSTALLED_VERSION=$(dox --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
  echo "✅ DOX CLI is already installed (version: $INSTALLED_VERSION)"
  echo ""
  echo "To reinstall, first uninstall by running:"
  echo "  rm -rf \$HOME/.dox"
  echo "  # Then remove DOX exports from your shell config file"
  echo ""
  exit 0
fi

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
export DOX_USER_BIN="${DOX_DIR}/bin"
export DOX_RESOURCES_DIR="${DOX_RESOURCES_DIR:-$HOME/dox_resources}"

rm -rf "$DOX_DIR" && mkdir -p "$DOX_DIR"
mkdir -p "$DOX_USER_BIN"
mkdir -p "$DOX_RESOURCES_DIR"

DOX_CLI_VERSION=${DOX_CLI_VERSION:-$(curl -s https://api.github.com/repos/dopxlab/dox-cli/releases/latest | jq -r '.tag_name')}

# Define the URL for the latest release tarball and the install directory
DOX_RELEASE_URL="https://github.com/dopxlab/dox-cli/releases/download/$DOX_CLI_VERSION/dox-cli.tar.gz"

# Download, extract, and set up DOX CLI
curl -LO $DOX_RELEASE_URL && tar -xzf dox-cli.tar.gz -C "$DOX_DIR" && rm -f dox-cli.tar.gz

#Version info is saved in version.txt
echo "The DOX CLI version is: $DOX_CLI_VERSION"
echo "$DOX_CLI_VERSION" > "$DOX_DIR/version.txt"

# Set permissions for DOX directories
chmod -R 755 "$DOX_DIR"
chmod -R 777 "$DOX_RESOURCES_DIR"  # Allow all users to write to resources directory

echo "✅ Set permissions: DOX_DIR (755), DOX_RESOURCES_DIR (777)"

# Detect shell configuration file
SHELL_CONFIG=""
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS - check for zsh first (default since Catalina), then bash
  if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
  else
    SHELL_CONFIG="$HOME/.bash_profile"
  fi
elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
  # Linux - use .bashrc
  SHELL_CONFIG="$HOME/.bashrc"
else
  # Fallback
  SHELL_CONFIG="$HOME/.bashrc"
fi

echo "Detected shell config: $SHELL_CONFIG"

# Append the bin directory to PATH in shell config if it's not already present
if ! grep -q "$DOX_USER_BIN" "$SHELL_CONFIG" 2>/dev/null; then
  echo "" >> "$SHELL_CONFIG"
  echo "# DOX CLI - Added by installer" >> "$SHELL_CONFIG"
  echo "export DOX_DIR=\"\$HOME/.dox\"" >> "$SHELL_CONFIG"
  echo "export DOX_USER_BIN=\"\${DOX_DIR}/bin\"" >> "$SHELL_CONFIG"
  echo "export DOX_RESOURCES_DIR=\"\${DOX_RESOURCES_DIR:-\$HOME/dox_resources}\"" >> "$SHELL_CONFIG"
  echo "export PATH=\"\${DOX_USER_BIN}:\$PATH\"" >> "$SHELL_CONFIG"
  echo "✅ Added DOX environment variables to $SHELL_CONFIG"
else
  echo "ℹ️  DOX already configured in $SHELL_CONFIG"
fi

# Detect OS and architecture for yq installation
OS_TYPE=""
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS_TYPE="darwin"
elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
  OS_TYPE="linux"
else
  echo "⚠️  Unsupported OS type: $OSTYPE"
  exit 1
fi

ARCH=$(uname -m)
# Normalize architecture
if [[ "$ARCH" == "aarch64" ]]; then
  ARCH="arm64"
elif [[ "$ARCH" == "x86_64" ]]; then
  ARCH="amd64"
fi

echo "Detected platform: $OS_TYPE-$ARCH"

# Check if yq is installed, if not, install it
if ! command -v yq &>/dev/null; then
  YQ_VERSION="v4.45.1"
  YQ_BINARY="yq_${OS_TYPE}_${ARCH}"
  YQ_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz"
  
  echo "Installing yq from: $YQ_URL"
  curl -sL "$YQ_URL" -o yq.tar.gz
  mkdir -p yq_temp && tar -xzf yq.tar.gz -C yq_temp
  mv "yq_temp/${YQ_BINARY}" "$DOX_USER_BIN/yq"
  chmod +x "$DOX_USER_BIN/yq"
  rm -rf yq.tar.gz yq_temp
  echo "✅ yq installed successfully."
else
  echo "ℹ️  yq already installed: $(command -v yq)"
fi

echo "✅ DOX CLI installed successfully!"

# Export path for current session
export PATH="$DOX_USER_BIN:$PATH"

# Test if DOX CLI is working
echo ""
echo "Current PATH: $PATH"
echo ""
echo "Testing DOX CLI..." 
source $SHELL_CONFIG
dox --version

echo ""
echo "================================================"
echo "Installation complete! 🎉"
echo "================================================"
echo ""
echo "To use DOX in the current session, run:"
echo "  source $SHELL_CONFIG"
echo ""
echo "Or start a new terminal session."
echo "================================================"