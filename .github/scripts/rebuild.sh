#!/usr/bin/env bash
set -euo pipefail

# Rebuild script for apache/casbin-website-v1-deprecated
# Runs on existing source tree (no clone). Installs deps, runs pre-build steps, builds.
# Expected to be run from inside the website/ directory of the repo.

# --- Node version ---
echo "=== Setting up Node.js via nvm ==="
export NVM_DIR="${HOME}/.nvm"
if [ ! -f "${NVM_DIR}/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi
# shellcheck disable=SC1091
source "${NVM_DIR}/nvm.sh"

# Docusaurus 1.x - use Node 16 for compatibility
nvm install 16
nvm use 16

echo "Node version: $(node --version)"
echo "npm version: $(npm --version)"

# --- Package manager + dependencies ---
echo "=== Installing yarn ==="
npm install -g yarn

echo "=== Installing dependencies ==="
yarn install --frozen-lockfile

# --- Build ---
echo "=== Building site ==="
yarn build

echo "[DONE] Build complete."
