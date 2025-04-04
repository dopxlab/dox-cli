#!/usr/bin/env bash

function deploy() {
  echo "🚀 Deploying Helm app..."
  # Replace with your actual bash logic for building and templating
  helm template "$DOX_DIR/custom/templates/helm"
}
