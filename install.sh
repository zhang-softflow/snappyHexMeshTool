#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 foamSHM contributors
#
# Install helper for foamSHM:
#   - links the Claude Code skill into ~/.claude/skills
#   - prints (or, with --bashrc, appends) the PATH setting
#
# Usage: ./install.sh [--bashrc] [--no-skill] [--uninstall] [--help]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SKILL_NAME="openfoam-snappyhexmesh"
SKILL_SRC="$REPO_DIR/skill/$SKILL_NAME"
SKILL_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
SKILL_DST="$SKILL_DIR/$SKILL_NAME"
BASHRC="$HOME/.bashrc"
MARK_BEGIN="# >>> foamSHM >>>"
MARK_END="# <<< foamSHM <<<"

do_bashrc=false
do_skill=true
uninstall=false

usage() {
    sed -n '4,9p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        --bashrc)    do_bashrc=true ;;
        --no-skill)  do_skill=false ;;
        --uninstall) uninstall=true ;;
        -h|--help)   usage ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

if $uninstall; then
    if [ -L "$SKILL_DST" ]; then
        rm "$SKILL_DST"
        echo "Removed skill link $SKILL_DST"
    fi
    if [ -f "$BASHRC" ] && grep -qF "$MARK_BEGIN" "$BASHRC"; then
        cp -p "$BASHRC" "$BASHRC.foamSHM.bak"
        sed -i "/^$MARK_BEGIN\$/,/^$MARK_END\$/d" "$BASHRC"
        echo "Removed PATH block from $BASHRC (backup: $BASHRC.foamSHM.bak)"
    fi
    echo "Database files (if any) remain in ${XDG_DATA_HOME:-$HOME/.local/share}/foamSHM"
    exit 0
fi

chmod +x "$REPO_DIR/foamSHM"

# Claude Code skill
if $do_skill; then
    mkdir -p "$SKILL_DIR"
    if [ -L "$SKILL_DST" ]; then
        if [ "$(readlink -f "$SKILL_DST")" = "$(readlink -f "$SKILL_SRC")" ]; then
            echo "Skill already linked: $SKILL_DST"
        else
            echo "Skill link exists but points elsewhere: $SKILL_DST -> $(readlink "$SKILL_DST")"
            echo "Remove it first if you want to replace it."
        fi
    elif [ -e "$SKILL_DST" ]; then
        echo "A skill named $SKILL_NAME already exists at $SKILL_DST (not a link); left unchanged."
    else
        ln -s "$SKILL_SRC" "$SKILL_DST"
        echo "Linked skill: $SKILL_DST -> $SKILL_SRC"
    fi
fi

# PATH
path_block="$MARK_BEGIN
export PATH=\"\$PATH:$REPO_DIR\"
$MARK_END"

if $do_bashrc; then
    if [ -f "$BASHRC" ] && grep -qF "$MARK_BEGIN" "$BASHRC"; then
        echo "PATH block already present in $BASHRC"
    else
        [ -f "$BASHRC" ] && cp -p "$BASHRC" "$BASHRC.foamSHM.bak"
        printf '\n%s\n' "$path_block" >> "$BASHRC"
        echo "Appended PATH block to $BASHRC (run: source $BASHRC)"
    fi
else
    case ":$PATH:" in
        *":$REPO_DIR:"*) echo "foamSHM directory is already in PATH." ;;
        *)
            echo
            echo "To use 'foamSHM' from anywhere, add this to your shell profile"
            echo "(or re-run with --bashrc to append it to $BASHRC):"
            echo
            echo "    export PATH=\"\$PATH:$REPO_DIR\""
            ;;
    esac
fi

echo
echo "Next steps:"
echo "  source <OpenFOAM>/etc/bashrc   # your OpenFOAM (ESI) installation"
echo "  foamSHM build                  # only needed if it is not OpenFOAM-v2606"
echo "  foamSHM search layer thickness"
