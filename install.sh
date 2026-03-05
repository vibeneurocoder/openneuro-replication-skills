#!/bin/bash
# Install OpenNeuro replication skills into a Claude Code project
#
# Usage:
#   bash install.sh /path/to/your/project
#   bash install.sh  # installs to current directory

set -e

TARGET="${1:-.}"

if [ ! -d "$TARGET" ]; then
    echo "Error: Target directory '$TARGET' does not exist."
    exit 1
fi

SKILLS_DIR="$TARGET/.claude/skills"
mkdir -p "$SKILLS_DIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"

if [ ! -d "$SKILLS_SRC" ]; then
    echo "Error: Skills source directory not found at $SKILLS_SRC"
    exit 1
fi

echo "Installing OpenNeuro replication skills..."
echo "  Source: $SKILLS_SRC"
echo "  Target: $SKILLS_DIR"
echo ""

INSTALLED=0
for skill in "$SKILLS_SRC"/*.md; do
    name=$(basename "$skill")
    if [ -f "$SKILLS_DIR/$name" ]; then
        echo "  [SKIP] $name (already exists — remove it first to update)"
    else
        cp "$skill" "$SKILLS_DIR/$name"
        echo "  [OK]   $name"
        INSTALLED=$((INSTALLED + 1))
    fi
done

echo ""
echo "Installed $INSTALLED skill(s) to $SKILLS_DIR"
echo ""
echo "Usage in Claude Code:"
echo "  > setup replication ds003645"
echo "  > read paper path/to/paper.pdf"
echo "  > replicate study ds003645"
echo "  > what packages do I need?"
echo ""
echo "Prerequisites:"
echo "  pip install numpy scipy matplotlib pandas mne awscli"
