#!/usr/bin/env bash
#
# sync-company-brain.sh - sync the company-wide "brain" (skills + agents) into your
# user-level Claude setup. macOS/Linux equivalent of Sync-CompanyBrain.ps1.
#
# Two-tier brain:
#   * LOCAL   - skills/agents you manage in this workspace's .claude folder (this Git repo).
#   * COMPANY - shared skills/agents from a company folder (usually a mounted network
#               share), copied into ~/.claude so they work in EVERY project.
#
# Company items are COPIED, not linked, so they keep working off the network too.
# Re-run this script to pick up company updates.
#
# A manifest records exactly which items came from the company brain, so a sync only ever
# updates or removes COMPANY items - your own skills/agents are never touched, and a name
# clash is skipped with a warning (your local copy wins).
#
# Client data and requirements are NOT copied - they are read in place from the share.
#
# Expected layout of the company brain folder:
#     <CompanyBrain>/
#         skills/<skill-name>/SKILL.md
#         agents/<agent-name>.md
#         clients/
#         requirements/
#
# Usage:
#   ./sync-company-brain.sh --path /Volumes/Share/CompanyBrain   # first-time setup
#   ./sync-company-brain.sh                                      # re-sync (remembered path)
#   ./sync-company-brain.sh --status                             # show what is synced
#   ./sync-company-brain.sh --remove                             # remove company items only

set -eu

claude_home="$HOME/.claude"
skills_dir="$claude_home/skills"
agents_dir="$claude_home/agents"
manifest="$claude_home/.company-brain-manifest"
user_memory="$claude_home/CLAUDE.md"

block_begin='<!-- BEGIN company-brain (managed by sync-company-brain) -->'
block_end='<!-- END company-brain -->'

usage() { sed -n '3,32p' "$0" | sed 's/^# \{0,1\}//'; }

path=""; do_status=0; do_remove=0
while [ $# -gt 0 ]; do
    case "$1" in
        --path)   path="${2:-}"; shift 2 ;;
        --status) do_status=1; shift ;;
        --remove) do_remove=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

prev_path=""
prev_skills=""
prev_agents=""
if [ -f "$manifest" ]; then
    while IFS= read -r line; do
        case "$line" in
            path=*)  prev_path="${line#path=}" ;;
            skill=*) prev_skills="$prev_skills ${line#skill=}" ;;
            agent=*) prev_agents="$prev_agents ${line#agent=}" ;;
        esac
    done < "$manifest"
fi

contains() {
    needle="$1"; shift
    for item in $1; do
        if [ "$item" = "$needle" ]; then return 0; fi
    done
    return 1
}

update_user_memory() {
    company="$1"
    refs="${2:-}"
    master="${3:-}"
    tmp="$claude_home/.claude-md.tmp"
    mkdir -p "$claude_home"
    if [ -f "$user_memory" ]; then
        awk -v b="$block_begin" -v e="$block_end" '
            { if (index($0,b)) skip=1
              if (!skip) print
              if (index($0,e)) skip=0 }
        ' "$user_memory" > "$tmp"
    else
        : > "$tmp"
    fi
    # trim trailing blank lines
    awk 'BEGIN{n=0} {lines[n++]=$0} END{last=n-1; while(last>=0 && lines[last]~/^[[:space:]]*$/) last--; for(i=0;i<=last;i++) print lines[i]}' "$tmp" > "$tmp.2"
    mv "$tmp.2" "$tmp"

    if [ -n "$company" ]; then
        if [ -s "$tmp" ]; then printf '\n\n' >> "$tmp"; fi
        {
            printf '%s\n' "$block_begin"
            printf '## Company brain\n\n'
            printf 'Shared company knowledge lives at: %s\n\n' "$company"
            if [ -n "$master" ]; then
                printf -- '- **Company master context: %s** - ALWAYS read and follow it,\n' "$master"
                printf -- '  in conjunction with any project or workspace CLAUDE.md. It carries the studio-wide\n'
                printf -- '  standards that apply to all work.\n'
            else
                printf -- '- No company master CLAUDE.md found on the share.\n'
            fi
            printf -- '- Company **skills** and **agents** from there are synced into your user-level .claude\n'
            printf -- '  folder, so they are available in every project.\n'
            if [ -n "$refs" ]; then
                printf -- '- Reference material on the share, read it IN PLACE: %s\n' "$refs"
            else
                printf -- '- No extra reference folders on the share yet.\n'
            fi
            printf -- '- Never copy client data or company reference material into a project or a Git repo.\n'
            printf -- '- Re-sync with sync-company-brain.sh (macOS/Linux) or Sync-CompanyBrain.ps1 (Windows).\n'
            printf '%s\n' "$block_end"
        } >> "$tmp"
    fi

    if [ -s "$tmp" ]; then mv "$tmp" "$user_memory"; else rm -f "$tmp" "$user_memory"; fi
}

# --- Status ------------------------------------------------------------------
if [ "$do_status" -eq 1 ]; then
    if [ -z "$prev_path" ]; then
        echo "No company brain configured yet."
        echo "Set it up with:  ./sync-company-brain.sh --path /Volumes/Share/CompanyBrain"
        exit 0
    fi
    echo "Company brain:  $prev_path"
    if [ -d "$prev_path" ]; then echo "Reachable now:  yes"; else echo "Reachable now:  no"; fi
    echo
    echo "Synced skills:"; for s in $prev_skills; do echo "  $s"; done
    echo "Synced agents:"; for a in $prev_agents; do echo "  $a"; done
    exit 0
fi

# --- Remove ------------------------------------------------------------------
if [ "$do_remove" -eq 1 ]; then
    for s in $prev_skills; do rm -rf "$skills_dir/$s"; done
    for a in $prev_agents; do rm -f "$agents_dir/$a"; done
    rm -f "$manifest"
    update_user_memory ""
    echo "Removed all company-synced skills and agents. Your own local ones are untouched."
    exit 0
fi

# --- Sync --------------------------------------------------------------------
company="$path"
if [ -z "$company" ]; then company="$prev_path"; fi
if [ -z "$company" ]; then
    echo "No company brain path set yet. Run once with:  --path /Volumes/Share/CompanyBrain" >&2
    exit 1
fi
if [ ! -d "$company" ]; then
    echo "Cannot reach the company brain at: $company" >&2
    echo "Check the network share is mounted and you are signed in." >&2
    exit 1
fi

mkdir -p "$skills_dir" "$agents_dir"

new_skills=""; new_agents=""; skipped=""

if [ -d "$company/skills" ]; then
    for dir in "$company"/skills/*; do
        [ -d "$dir" ] || continue
        [ -f "$dir/SKILL.md" ] || continue
        name="$(basename "$dir")"
        target="$skills_dir/$name"
        if [ -e "$target" ] && ! contains "$name" "$prev_skills"; then
            skipped="$skipped\n  skill '$name' - you already have a local skill with that name"
            continue
        fi
        rm -rf "$target"
        cp -R "$dir" "$target"
        new_skills="$new_skills $name"
    done
fi

if [ -d "$company/agents" ]; then
    for file in "$company"/agents/*.md; do
        [ -f "$file" ] || continue
        name="$(basename "$file")"
        target="$agents_dir/$name"
        if [ -e "$target" ] && ! contains "$name" "$prev_agents"; then
            skipped="$skipped\n  agent '$name' - you already have a local agent with that name"
            continue
        fi
        cp -f "$file" "$target"
        new_agents="$new_agents $name"
    done
fi

# Prune items that have gone from the company brain (company items only)
for s in $prev_skills; do
    if ! contains "$s" "$new_skills"; then
        if [ -e "$skills_dir/$s" ]; then
            rm -rf "$skills_dir/$s"
            echo "Removed (no longer in company brain): skill $s"
        fi
    fi
done
for a in $prev_agents; do
    if ! contains "$a" "$new_agents"; then
        if [ -e "$agents_dir/$a" ]; then
            rm -f "$agents_dir/$a"
            echo "Removed (no longer in company brain): agent $a"
        fi
    fi
done

{
    printf 'path=%s\n' "$company"
    for s in $new_skills; do printf 'skill=%s\n' "$s"; done
    for a in $new_agents; do printf 'agent=%s\n' "$a"; done
} > "$manifest"

# Any folder other than skills/agents is reference material, read in place (not copied)
refs=""
for d in "$company"/*; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    if [ "$n" != "skills" ] && [ "$n" != "agents" ]; then
        if [ -z "$refs" ]; then refs="$n"; else refs="$refs, $n"; fi
    fi
done

# The company master CLAUDE.md: in the brain folder, or at the share root above it
master=""
if [ -f "$company/CLAUDE.md" ]; then
    master="$company/CLAUDE.md"
elif [ -f "$(dirname "$company")/CLAUDE.md" ]; then
    master="$(dirname "$company")/CLAUDE.md"
fi

update_user_memory "$company" "$refs" "$master"

if [ -n "$master" ]; then
    echo "Master context:  $master  (read in place, alongside local CLAUDE.md)"
fi

n_skills=0; for s in $new_skills; do n_skills=$((n_skills+1)); done
n_agents=0; for a in $new_agents; do n_agents=$((n_agents+1)); done

echo "Company brain:  $company"
echo "Synced $n_skills skill(s) and $n_agents agent(s) into $claude_home"
for s in $new_skills; do echo "  skill  $s"; done
for a in $new_agents; do echo "  agent  $a"; done
if [ -n "$skipped" ]; then
    echo
    echo "Skipped (your local copy wins):"
    printf '%b\n' "$skipped" | sed '/^$/d'
fi
echo
echo "Client data and requirements are read in place from the share - they are not copied."
