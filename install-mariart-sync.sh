#!/usr/bin/env bash
#
# install-mariart-sync.sh - install the Mariart plugin auto-sync hook (site clone -> main).
# macOS/Linux equivalent of Install-MariartSync.ps1.
#
# For every CONSUMING clone of the Mariart plugin repo on this machine (a Local site's
# wp-content/plugins/mariart other than the canonical one), install a pre-push git hook
# that fast-forwards the canonical main Mariart working copy to the pushed commit.
#
# Git has no client-side post-push hook, so the sync runs at pre-push. Every clone is on
# the one machine, so the destination is fast-forwarded directly from the pushing repo.
# The hook only ever fast-forwards, and only when the main copy is clean and on the target
# branch. Nothing is committed to any repo - hooks and local git config are per-clone.
#
# Usage:
#   ./install-mariart-sync.sh                     # discover consuming clones and wire them up
#   ./install-mariart-sync.sh --status            # show what is wired up
#   ./install-mariart-sync.sh --uninstall         # remove hook + config
#   ./install-mariart-sync.sh --target PATH       # main Mariart copy (default: ~/Local Sites/...)
#   ./install-mariart-sync.sh --source PATH ...   # wire specific clone(s) instead of discovering
#   ./install-mariart-sync.sh --force             # replace a different existing pre-push hook

set -eu

script_dir="$(cd "$(dirname "$0")" && pwd -P)"
template="$script_dir/tools/mariart-sync/pre-push.sh"
marker="mariart-sync"

target="$HOME/Local Sites/mariart/app/public/wp-content/plugins/mariart"
branch="main"
remote="origin"
do_status=0
do_uninstall=0
force=0
sources=()

usage() { sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
    case "$1" in
        --target)    target="${2:-}"; shift 2 ;;
        --source)    sources+=("${2:-}"); shift 2 ;;
        --branch)    branch="${2:-}"; shift 2 ;;
        --remote)    remote="${2:-}"; shift 2 ;;
        --status)    do_status=1; shift ;;
        --uninstall) do_uninstall=1; shift ;;
        --force)     force=1; shift ;;
        -h|--help)   usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

is_git_repo() {
    [ -n "${1:-}" ] || return 1
    [ -e "$1" ] || return 1
    git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

git_dir() { git -C "$1" rev-parse --absolute-git-dir 2>/dev/null; }

hook_path() {
    local g
    g="$(git_dir "$1")" || return 1
    [ -n "$g" ] || return 1
    printf '%s/hooks/pre-push' "$g"
}

origin_url() { git -C "$1" config --get remote.origin.url 2>/dev/null; }

norm_url() { printf '%s' "${1:-}" | tr 'A-Z' 'a-z' | sed -e 's/\.git$//' -e 's:/*$::'; }

real_path() { (cd "$1" 2>/dev/null && pwd -P) || printf '%s' "$1"; }

local_sites_root() {
    case "$1" in
        */Local\ Sites/*) printf '%s' "${1%%/Local Sites/*}/Local Sites" ;;
        *) return 1 ;;
    esac
}

find_sources() {
    local tpath="$1" torigin="$2" root d cand
    root="$(local_sites_root "$tpath")" || return 0
    [ -d "$root" ] || return 0
    for d in "$root"/*/; do
        cand="${d}app/public/wp-content/plugins/mariart"
        is_git_repo "$cand" || continue
        [ "$(real_path "$cand")" != "$(real_path "$tpath")" ] || continue
        [ "$(norm_url "$(origin_url "$cand")")" = "$(norm_url "$torigin")" ] || continue
        printf '%s\n' "$cand"
    done
}

install_one() {
    local src="$1" hook hookdir
    hook="$(hook_path "$src")" || { echo "  SKIP (no git dir) $src"; return; }
    hookdir="$(dirname "$hook")"
    mkdir -p "$hookdir"
    if [ -e "$hook" ] && [ "$force" -ne 1 ]; then
        if ! grep -q "$marker" "$hook" 2>/dev/null; then
            echo "  SKIP  $src"
            echo "        a different pre-push hook already exists; re-run with --force to replace it."
            return
        fi
    fi
    # Copy the hook, forcing LF endings, and make it executable.
    tr -d '\r' < "$template" > "$hook"
    chmod +x "$hook"
    git -C "$src" config mariart.sync.target "$target" >/dev/null
    git -C "$src" config mariart.sync.branch "$branch" >/dev/null
    git -C "$src" config mariart.sync.remote "$remote" >/dev/null
    echo "  OK    $src"
}

uninstall_one() {
    local src="$1" hook removed=0
    hook="$(hook_path "$src")" || hook=""
    if [ -n "$hook" ] && [ -e "$hook" ] && grep -q "$marker" "$hook" 2>/dev/null; then
        rm -f "$hook"
        removed=1
    fi
    git -C "$src" config --unset mariart.sync.target 2>/dev/null || true
    git -C "$src" config --unset mariart.sync.branch 2>/dev/null || true
    git -C "$src" config --unset mariart.sync.remote 2>/dev/null || true
    if [ "$removed" -eq 1 ]; then echo "  REMOVED  $src"; else echo "  cleared config (no Mariart hook found)  $src"; fi
}

show_one() {
    local src="$1" hook installed="false"
    hook="$(hook_path "$src")" || hook=""
    if [ -n "$hook" ] && [ -e "$hook" ] && grep -q "$marker" "$hook" 2>/dev/null; then
        installed="true"
    fi
    echo "  $src"
    echo "      hook installed : $installed"
    echo "      target         : $(git -C "$src" config --get mariart.sync.target 2>/dev/null)"
    echo "      branch/remote  : $(git -C "$src" config --get mariart.sync.branch 2>/dev/null) / $(git -C "$src" config --get mariart.sync.remote 2>/dev/null)"
}

# --- Main ---------------------------------------------------------------------
[ -f "$template" ] || { echo "Hook template not found: $template" >&2; exit 1; }
is_git_repo "$target" || { echo "Target is not a git repository: $target" >&2; exit 1; }
torigin="$(origin_url "$target")"

echo "Mariart plugin sync  (site clone -> main)"
echo "Main (target): $target"
echo "Remote origin: $torigin"
echo "Branch/remote: $branch / $remote"
echo

src_list=()
if [ "${#sources[@]}" -gt 0 ]; then
    for s in "${sources[@]}"; do
        if is_git_repo "$s"; then src_list+=("$s"); else echo "  (not a git repo, ignored) $s"; fi
    done
else
    while IFS= read -r line; do
        [ -n "$line" ] && src_list+=("$line")
    done < <(find_sources "$target" "$torigin")
fi

if [ "${#src_list[@]}" -eq 0 ]; then
    echo "No consuming clones found to wire up."
    echo "(Looked for sibling Local sites with a clone of the same repo.)"
    exit 0
fi

if [ "$do_status" -eq 1 ]; then
    echo "Consuming clones:"
    for s in "${src_list[@]}"; do show_one "$s"; done
    exit 0
fi
if [ "$do_uninstall" -eq 1 ]; then
    echo "Removing hook + config from consuming clones:"
    for s in "${src_list[@]}"; do uninstall_one "$s"; done
    exit 0
fi

echo "Wiring up consuming clones:"
for s in "${src_list[@]}"; do install_one "$s"; done
echo
echo "Done. Push the plugin from any wired clone and the main copy fast-forwards to match."
