#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/apache/casbin-website-v1-deprecated"
BRANCH="master"
REPO_DIR="source-repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Clone (skip if already exists) ---
if [ ! -d "$REPO_DIR" ]; then
    echo "=== Cloning repository ==="
    git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
else
    echo "=== source-repo already exists, skipping clone ==="
fi

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
cd "$REPO_DIR/website"
yarn install --frozen-lockfile

# --- Apply fixes.json if present ---
FIXES_JSON="$SCRIPT_DIR/fixes.json"
if [ -f "$FIXES_JSON" ]; then
    echo "[INFO] Applying content fixes..."
    node -e "
    const fs = require('fs');
    const path = require('path');
    const fixes = JSON.parse(fs.readFileSync('$FIXES_JSON', 'utf8'));
    for (const [file, ops] of Object.entries(fixes.fixes || {})) {
        if (!fs.existsSync(file)) { console.log('  skip (not found):', file); continue; }
        let content = fs.readFileSync(file, 'utf8');
        for (const op of ops) {
            if (op.type === 'replace' && content.includes(op.find)) {
                content = content.split(op.find).join(op.replace || '');
                console.log('  fixed:', file, '-', op.comment || '');
            }
        }
        fs.writeFileSync(file, content);
    }
    for (const [file, cfg] of Object.entries(fixes.newFiles || {})) {
        const c = typeof cfg === 'string' ? cfg : cfg.content;
        fs.mkdirSync(path.dirname(file), {recursive: true});
        fs.writeFileSync(file, c);
        console.log('  created:', file);
    }
    "
fi

echo "[DONE] Repository is ready for docusaurus commands."
