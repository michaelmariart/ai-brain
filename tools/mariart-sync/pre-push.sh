#!/bin/sh
#
# Mariart plugin sync - pre-push hook  (direction: site clone -> main)
#
# When the Mariart plugin is pushed from a CONSUMING site clone (e.g. Zoom Car Wash),
# fast-forward the canonical "main Mariart" working copy (mariart.local) to the same
# commit, so the main copy always reflects the latest pushed plugin code.
#
# Why pre-push, not post-push:
#   Git has no client-side post-push hook. This runs at pre-push, but every clone is on
#   the one machine, so the destination is fast-forwarded directly from THIS repo - the
#   commits being pushed already exist here locally, even though origin does not have
#   them yet. In the normal (successful) push this is identical to "pull after push",
#   with no network round-trip and no timing race.
#
# Configured per repo by the installer (git config, local to the pushing repo):
#   mariart.sync.target  - absolute path of the destination (main Mariart) working copy
#   mariart.sync.branch  - branch to keep in sync           (default: main)
#   mariart.sync.remote  - only sync when pushing here      (default: origin)
#
# SAFETY
#   * This is a pre-push hook, so it MUST always exit 0 - a non-zero exit would ABORT
#     the developer's push. Every path below ends in exit 0.
#   * The destination is only ever FAST-FORWARDED, and only when it is clean and on the
#     target branch. If it has uncommitted or diverged work, the sync is skipped with a
#     warning and nothing is touched.

remote_name="$1"

target="$(git config --get mariart.sync.target || true)"
branch="$(git config --get mariart.sync.branch || echo main)"
want_remote="$(git config --get mariart.sync.remote || echo origin)"

# Not configured -> do nothing.
[ -n "$target" ] || exit 0

# Only react to the intended remote.
if [ -n "$want_remote" ] && [ "$remote_name" != "$want_remote" ]; then
    exit 0
fi

warn() { echo "mariart-sync: $*" >&2; }

source_repo="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$source_repo" ] || exit 0

# Never sync a repo into itself (resolve real paths so a junction to the same folder
# is caught).
resolve() { (cd "$1" 2>/dev/null && pwd -P) || printf '%s' "$1"; }
if [ "$(resolve "$source_repo")" = "$(resolve "$target")" ]; then
    exit 0
fi

# Is the target branch among the refs being pushed? stdin lines are:
#   <local ref> <local sha> <remote ref> <remote sha>
pushed_sha=""
while read -r local_ref local_sha _remote_ref _remote_sha; do
    if [ "$local_ref" = "refs/heads/$branch" ]; then
        pushed_sha="$local_sha"
    fi
done
[ -n "$pushed_sha" ] || exit 0

# A branch deletion pushes an all-zero sha - ignore it.
case "$pushed_sha" in
    *[!0]*) : ;;
    *) exit 0 ;;
esac

if [ ! -e "$target/.git" ]; then
    warn "target is not a git repo, skipped: $target"
    exit 0
fi

# Destination must be clean and on the target branch, or we leave it untouched.
dest_branch="$(git -C "$target" rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ "$dest_branch" != "$branch" ]; then
    warn "main copy is on '$dest_branch', not '$branch' - skipped (nothing changed)"
    exit 0
fi
if [ -n "$(git -C "$target" status --porcelain 2>/dev/null)" ]; then
    warn "main copy has uncommitted changes - skipped (nothing touched): $target"
    exit 0
fi

# Already at the pushed commit?
if [ "$(git -C "$target" rev-parse HEAD 2>/dev/null)" = "$pushed_sha" ]; then
    exit 0
fi

# Bring the pushed commits into the destination from THIS local repo, then fast-forward
# only. If the destination has diverged it is NOT a fast-forward, so we never force it.
if ! git -C "$target" fetch --quiet "$source_repo" "$branch" 2>/dev/null; then
    warn "could not fetch commits into the main copy - skipped: $target"
    exit 0
fi
before_ff="$(git -C "$target" rev-parse HEAD 2>/dev/null)"
if git -C "$target" merge --ff-only --quiet FETCH_HEAD 2>/dev/null; then
    if [ "$before_ff" != "$(git -C "$target" rev-parse HEAD 2>/dev/null)" ]; then
        warn "main Mariart copy fast-forwarded to $(git -C "$target" rev-parse --short HEAD)"
    fi
else
    warn "main copy has diverged from this push - left unchanged, resolve by hand: $target"
fi

exit 0
