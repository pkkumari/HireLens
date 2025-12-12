#!/bin/bash
# Script to push HireLens to GitHub
# This will prompt for your GitHub credentials

cd "$(dirname "$0")"

echo "Pushing HireLens to GitHub..."
echo "Repository: https://github.com/pkkumari/HireLens.git"
echo ""
echo "You'll be prompted for:"
echo "  - Username: your GitHub username"
echo "  - Password: use a Personal Access Token (not your password)"
echo ""
echo "Create a token at: https://github.com/settings/tokens"
echo ""

git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to GitHub!"
    echo "View your repository at: https://github.com/pkkumari/HireLens"
else
    echo ""
    echo "❌ Push failed. Please check your credentials and try again."
fi

