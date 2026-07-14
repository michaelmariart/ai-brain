#!/usr/bin/env bash
#
# set-projects-folder.sh - create or relocate the whole "projects" workspace.
# macOS / Linux equivalent of Set-ProjectsFolder.ps1 (Windows users: use that instead).
#
# All project work lives in ./projects, which is ignored by Git. By default it is a plain
# folder inside the repo, but it can live ANYWHERE on this machine and be linked in via a
# symbolic link - you always open your work through ./projects either way. No sudo needed.
#
# Usage:
#   ./set-projects-folder.sh                # keep projects inside the repo (default)
#   ./set-projects-folder.sh --path DIR     # store projects at DIR, linked in as ./projects
#   ./set-projects-folder.sh --status       # show where projects currently lives

set -eu

repo="$(cd "$(dirname "$0")" && pwd)"
link="$repo/projects"
gitignore="$repo/.gitignore"

usage() { sed -n '3,14p' "$0" | sed 's/^# \{0,1\}//'; }

path=""
status=0
while [ $# -gt 0 ]; do
    case "$1" in
        --path)   path="${2:-}"; shift 2 ;;
        --status) status=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

# --- Status only -------------------------------------------------------------
if [ "$status" -eq 1 ]; then
    if [ -L "$link" ]; then
        echo "projects  [symlink]        ->  $(readlink "$link")"
    elif [ -d "$link" ]; then
        echo "projects  [folder in repo] ->  $link"
    else
        echo "No 'projects' folder yet. Run  ./set-projects-folder.sh  to create it."
    fi
    exit 0
fi

# --- Make sure Git ignores the workspace -------------------------------------
if ! grep -qxF 'projects/' "$gitignore" 2>/dev/null; then
    printf '\n# Local projects workspace - not tracked; may live anywhere on this machine\nprojects/\n' >> "$gitignore"
    echo "Added 'projects/' to .gitignore"
fi

if [ -n "$path" ]; then
    # --- Relocate to a chosen path -------------------------------------------
    mkdir -p "$path"
    target="$(cd "$path" && pwd)"

    if [ -L "$link" ]; then
        rm "$link"                       # remove old link only; data at target is kept
    elif [ -d "$link" ]; then
        if [ -n "$(ls -A "$link" 2>/dev/null)" ]; then
            find "$link" -mindepth 1 -maxdepth 1 -exec mv -f {} "$target"/ \;
            echo "Moved existing projects into  $target"
        fi
        rmdir "$link"
    fi

    ln -s "$target" "$link"
    echo "projects  [symlink]  ->  $target"
else
    # --- Default: a plain folder inside the repo -----------------------------
    if [ ! -e "$link" ] && [ ! -L "$link" ]; then
        mkdir -p "$link"
        echo "Created  projects  (folder inside the repo)"
    elif [ -L "$link" ]; then
        echo "projects is currently linked to $(readlink "$link"). Leaving it. Pass --path to change it."
    else
        echo "projects folder already exists inside the repo. Nothing to do."
    fi
fi

echo
echo "Done. Put each project in its own subfolder under  ./projects/"
echo "Check the location any time with:  ./set-projects-folder.sh --status"
