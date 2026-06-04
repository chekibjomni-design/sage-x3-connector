#!/bin/bash
# ============================================================
# Push Sage X3 Connector to GitHub
# ============================================================
# Usage:
#   1. Go to https://github.com/settings/tokens
#   2. Generate a classic token with scope "repo"
#   3. Copy the token
#   4. Run:   bash push_to_github.sh
# ============================================================

set -e

# Prevent token from being saved in bash history
unset HISTFILE

echo "=========================================="
echo "  Sage X3 Connector - GitHub Publication"
echo "=========================================="

# --- Ask for token (masked input) ---
echo ""
echo "Enter your GitHub classic token (scope: repo):"
read -rs GITHUB_TOKEN
echo ""

GITHUB_USER="chekib"
REPO_NAME="sage-x3-connector"
echo "Username : $GITHUB_USER"
echo "Repo     : $GITHUB_USER/$REPO_NAME"

# --- Check token validity ---
echo ""
echo "[1/5] Checking token..."
HTTP_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user)
if [ "$HTTP_CHECK" != "200" ]; then
  echo "  Invalid token (HTTP $HTTP_CHECK). Check your token and try again."
  exit 1
fi
echo "  Token OK"

# --- Init Git ---
echo ""
echo "[2/5] Initializing local git repo..."
cd "$(dirname "$0")"
git init --quiet 2>/dev/null || true
git checkout -b main 2>/dev/null || true

# Use noreply GitHub email
GITHUB_EMAIL=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user | python3 -c \
  "import sys,json; print(json.load(sys.stdin).get('email',''))" 2>/dev/null || echo "")
if [ -z "$GITHUB_EMAIL" ]; then
  GITHUB_EMAIL="$GITHUB_USER@users.noreply.github.com"
fi

git config user.name "Chekib Jomni"
git config user.email "$GITHUB_EMAIL"
echo "  Git configured ($GITHUB_EMAIL)"

# --- Create repo on GitHub ---
echo ""
echo "[3/5] Creating GitHub repository..."
EXISTS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GITHUB_USER/$REPO_NAME)

if [ "$EXISTS" = "404" ]; then
  curl -sf -H "Authorization: token $GITHUB_TOKEN" \
    -X POST https://api.github.com/user/repos \
    -d "{
      \"name\": \"$REPO_NAME\",
      \"description\": \"Single-file Python module to connect to Sage X3 (SQL Server) via ODBC. Supports WSL gateway, named instances, and .env configuration.\",
      \"homepage\": \"https://github.com/$GITHUB_USER/$REPO_NAME\",
      \"private\": false,
      \"has_issues\": true,
      \"has_wiki\": true
    }" > /dev/null
  echo "  Created: https://github.com/$GITHUB_USER/$REPO_NAME"
elif [ "$EXISTS" = "200" ]; then
  echo "  Repository already exists"
else
  echo "  Error (HTTP $EXISTS). Check token has 'repo' scope."
  GITHUB_TOKEN=""
  exit 1
fi

# --- Add & commit ---
echo ""
echo "[4/5] Committing files..."
git add -A
git commit -m "Initial release: Sage X3 ODBC Connector

Single-file Python module for connecting to Sage X3 (SQL Server) via ODBC.

Features:
- Single-file, copy-paste into any project
- Three connection modes: named instance, host:port, WSL2 gateway
- .env support via python-dotenv
- Read-only mode with ApplicationIntent=ReadOnly
- No hardcoded credentials (configured via environment)

Includes:
- sage_x3_connector.py - main module
- sage-x3-connector/SKILL.md - Codebuff skill
- README.md - full documentation
- LICENSE - MIT" --quiet
echo "  Committed"

# --- Push ---
echo ""
echo "[5/5] Pushing to GitHub..."
git remote add origin https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$GITHUB_USER/$REPO_NAME.git
git push -u origin main --quiet

# Wipe token from git remote immediately
git remote set-url origin https://github.com/$GITHUB_USER/$REPO_NAME.git

echo "  Pushed successfully"
echo ""
echo "=========================================="
echo "  Publication complete!"
echo "=========================================="
echo ""
echo "  https://github.com/$GITHUB_USER/$REPO_NAME"
echo ""
echo "  To install the skill with Codebuff:"
echo "    npx skills add $GITHUB_USER/$REPO_NAME"
echo ""

# Clear token from memory
GITHUB_TOKEN=""
