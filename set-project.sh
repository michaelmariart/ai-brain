#!/usr/bin/env bash
#
# set-project.sh - manage individual projects; each can live anywhere on this machine.
# macOS / Linux equivalent of Set-Project.ps1 (Windows users: use that instead).
#
# Projects are reached through ./projects/<name>. A project can be a plain subfolder there,
# or live elsewhere on this machine and be linked in with a symbolic link. Projects do not
# have to be centralised in one folder. No sudo needed. Linked projects live outside
# ./projects, so Git never tracks them.
#
# Usage:
#   ./set-project.sh                              # list every project and where it lives
#   ./set-project.sh --name NAME --path DIR       # link / move / re-point a project
#   ./set-project.sh --name NAME --unlink         # remove the link (files are kept)
#
# What --path does depends on the current state:
#   * projects/<NAME> does not exist   -> link it to DIR (DIR is created if missing)
#   * projects/<NAME> is a real folder -> its contents are MOVED to DIR, then linked
#   * projects/<NAME> is already a link -> re-pointed to DIR (old data left in place)

set -eu

repo="$(cd "$(dirname "$0")" && pwd)"
projects="$repo/projects"

usage() { sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'; }

name=""; path=""; unlink=0; list=0
while [ $# -gt 0 ]; do
    case "$1" in
        --name)   name="${2:-}"; shift 2 ;;
        --path)   path="${2:-}"; shift 2 ;;
        --unlink) unlink=1; shift ;;
        --list)   list=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

if [ ! -d "$projects" ]; then
    echo "No 'projects' folder yet. Run  ./set-projects-folder.sh  first." >&2
    exit 1
fi

show_projects() {
    found=0
    for entry in "$projects"/*; do
        [ -e "$entry" ] || [ -L "$entry" ] || continue
        found=1
        n="$(basename "$entry")"
        if [ -L "$entry" ]; then
            printf '  %-34s ->  %s\n' "$n" "$(readlink "$entry")"
        elif [ -d "$entry" ]; then
            printf '  %-34s     (in workspace)\n' "$n"
        fi
    done
    [ "$found" -eq 1 ] || echo "  (no projects yet)"
}

# --- List (explicit, or when nothing else is asked for) ----------------------
if [ "$list" -eq 1 ] || { [ -z "$name" ] && [ -z "$path" ] && [ "$unlink" -eq 0 ]; }; then
    echo "Projects in  $projects"
    show_projects
    exit 0
fi

link="$projects/$name"

# --- Unlink ------------------------------------------------------------------
if [ "$unlink" -eq 1 ]; then
    [ -n "$name" ] || { echo "Use  --name NAME  with --unlink." >&2; exit 1; }
    if [ ! -e "$link" ] && [ ! -L "$link" ]; then
        echo "No project named '$name'." >&2; exit 1
    fi
    if [ ! -L "$link" ]; then
        echo "'$name' is a real folder in the workspace, not a link. Leaving it alone to avoid data loss. Move or delete it manually if you are sure." >&2
        exit 1
    fi
    where="$(readlink "$link")"
    rm "$link"                           # removes only the symlink, never the target
    echo "Unlinked '$name'. Its files remain at:  $where"
    exit 0
fi

# --- Set: link / move / re-point ---------------------------------------------
if [ -z "$name" ] || [ -z "$path" ]; then
    echo "Usage:  --name NAME --path DIR   |   --list   |   --name NAME --unlink" >&2
    exit 1
fi

if [ ! -e "$link" ] && [ ! -L "$link" ]; then
    # LINK: point projects/<name> at DIR (create DIR if it does not exist yet)
    mkdir -p "$path"
    target="$(cd "$path" && pwd)"
    ln -s "$target" "$link"
    echo "Linked   projects/$name  ->  $target"

elif [ -L "$link" ]; then
    # RE-POINT: swap an existing link to a new location (old data left in place)
    old="$(readlink "$link")"
    mkdir -p "$path"
    target="$(cd "$path" && pwd)"
    rm "$link"
    ln -s "$target" "$link"
    echo "Re-pointed  projects/$name  ->  $target"
    echo "(Old location left untouched:  $old)"

else
    # MOVE: relocate a real in-workspace project out to DIR, then link it back
    if [ -e "$path" ] && [ -n "$(ls -A "$path" 2>/dev/null)" ]; then
        echo "$path is not empty. Choose an empty or new folder to move '$name' into." >&2
        exit 1
    fi
    if [ -d "$path" ]; then
        rmdir "$path"                    # empty target: remove so we can move into place
    fi
    mkdir -p "$(dirname "$path")"
    parent="$(cd "$(dirname "$path")" && pwd)"
    target="$parent/$(basename "$path")"
    mv "$link" "$target"
    ln -s "$target" "$link"
    echo "Moved    projects/$name  ->  $target   and linked it back in"
fi

echo
echo "Projects now:"
show_projects
