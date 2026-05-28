#!/bin/bash

# =============================================================================
# setup-secrets.sh — Automatically push Docker Hub secrets to GitHub repo
# Run this ONCE after init.sh to configure CI pipeline secrets.
# Usage: bash setup-secrets.sh
# Requirements: GitHub CLI (gh) must be installed — https://cli.github.com
# =============================================================================

set -e  # stop immediately if any command fails

# -----------------------------------------------------------------------------
# CONFIG — must match what you set in init.sh
# -----------------------------------------------------------------------------
GITHUB_USERNAME="DevOps-engineer-dev"
REPO_NAME="new-project"

echo "================================================"
echo " GitHub Secrets Setup for $REPO_NAME"
echo "================================================"

# -----------------------------------------------------------------------------
# Step 1: Check that GitHub CLI is installed
# -----------------------------------------------------------------------------
echo ""
echo "[1/4] Checking GitHub CLI is installed..."

if ! command -v gh &> /dev/null; then
  echo ""
  echo " ERROR: GitHub CLI (gh) is not installed."
  echo " Download it from: https://cli.github.com"
  echo " Install it, then re-run this script."
  exit 1
fi

echo "      GitHub CLI found: $(gh --version | head -n 1)"

# -----------------------------------------------------------------------------
# Step 2: Check that you are logged in to GitHub CLI
# -----------------------------------------------------------------------------
echo ""
echo "[2/4] Checking GitHub CLI authentication..."

if ! gh auth status &> /dev/null; then
  echo ""
  echo " You are not logged in to GitHub CLI."
  echo " Running 'gh auth login' now — follow the prompts..."
  echo ""
  gh auth login
fi

echo "      GitHub CLI authenticated."

# -----------------------------------------------------------------------------
# Step 3: Prompt for Docker Hub credentials
#         -s flag hides input so credentials are not visible on screen
# -----------------------------------------------------------------------------
echo ""
echo "[3/4] Enter your Docker Hub credentials."
echo "      (These will be sent directly to GitHub as encrypted secrets."
echo "       They will NOT be saved to any file.)"
echo ""

read -p "      Docker Hub username: " DOCKER_USERNAME
read -s -p "      Docker Hub access token: " DOCKER_TOKEN
echo ""  # newline after hidden input

# -----------------------------------------------------------------------------
# Step 4: Push both secrets to GitHub repo
# -----------------------------------------------------------------------------
echo ""
echo "[4/4] Pushing secrets to GitHub repo..."

gh secret set DOCKERHUB_USERNAME \
  --body "$DOCKER_USERNAME" \
  --repo "$GITHUB_USERNAME/$REPO_NAME"

gh secret set DOCKERHUB_TOKEN \
  --body "$DOCKER_TOKEN" \
  --repo "$GITHUB_USERNAME/$REPO_NAME"

echo ""
echo "================================================"
echo " Done! Both secrets have been added to:"
echo " https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo ""
echo " Next steps:"
echo "   1. Go to your GitHub repo"
echo "   2. Click the Actions tab"
echo "   3. Click the failed workflow"
echo "   4. Click 'Re-run jobs'"
echo "   This time it should pass with a green tick."
echo "================================================"
