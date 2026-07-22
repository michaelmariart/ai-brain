# The two-tier brain

This workspace has **two layers of knowledge**, and they stay separate on purpose:

| Tier | Lives in | Applies to | Managed by |
|---|---|---|---|
| **Local** | `AI Brain/.claude/skills` and `.claude/agents` | only this workspace | you, in this Git repo |
| **Company** | your user-level `~/.claude/skills` and `~/.claude/agents` | **every** project on your machine | synced from the company share |

Your local skills and agents are yours: they live in this repo, you edit them freely, and a
company sync never touches them. The company tier is shared knowledge everyone gets.

## The master context file

At the **root of the clients share** sits `CLAUDE.md` (on this machine, `Z:\CLAUDE.md`) —
the Mariart Studio master brain. It holds the standards that apply to **all** studio work:
Australian English, client confidentiality, verbatim transfers, and which skills to load
for which job.

**It must be used in conjunction with the local `CLAUDE.md` in this workspace.** Claude
loads it automatically for sessions opened *inside* the share, but **not** when you're
working here in the local AI Brain on your own drive — so it is referenced explicitly from
this workspace's `CLAUDE.md`, and the sync writes a pointer to it into your user-level
`~/.claude/CLAUDE.md` so it applies in every project.

Where the two overlap, the **master context wins**; the local `CLAUDE.md` adds
workspace-specific conventions (project layout, the tooling scripts, Git habits) on top.

The sync finds it automatically — in the company brain folder, or at the share root above
it — so the pointer stays correct even if the drive mapping changes. It is **read in place,
never copied**: Alison maintains it and it is read-only for everyone else.

## The company brain folder

A shared folder (usually a network share) laid out like this:

```
<CompanyBrain>/
├── skills/                 ← one folder per skill, each with a SKILL.md
│   └── <skill-name>/SKILL.md
├── agents/                 ← one .md file per agent
│   └── <agent-name>.md
├── clients/                ← client data (read in place, never copied)
└── requirements/           ← company requirements & standards (read in place)
```

**Skills and agents are copied** to your machine so they work in every project — and keep
working when you're off the network. **Client data and requirements are not copied**: they
are read straight from the share, so there is only ever one copy of client information.

## Setting it up

The sync scripts are the studio's **canonical copies on the share** (in the company brain
folder) — they are not duplicated in this repo, so run them from there. Run once, pointing
at the share:

```powershell
# Windows
& "Z:\AI BRAIN\Sync-CompanyBrain.ps1" -Path "Z:\AI BRAIN"
```
```bash
# macOS / Linux
"/Volumes/Clients_Folder/AI BRAIN/sync-company-brain.sh" --path "/Volumes/Clients_Folder/AI BRAIN"
```

The location is remembered, so afterwards you just run the script with no arguments.

| Task | Windows | macOS / Linux |
|---|---|---|
| Sync / pick up company updates | `& "Z:\AI BRAIN\Sync-CompanyBrain.ps1"` | `"…/AI BRAIN/sync-company-brain.sh"` |
| See what's synced | `& "Z:\AI BRAIN\Sync-CompanyBrain.ps1" -Status` | `"…/AI BRAIN/sync-company-brain.sh" --status` |
| Remove company items | `& "Z:\AI BRAIN\Sync-CompanyBrain.ps1" -Remove` | `"…/AI BRAIN/sync-company-brain.sh" --remove` |
| Point at a new location | `& "Z:\AI BRAIN\Sync-CompanyBrain.ps1" -Path "…"` | `"…/AI BRAIN/sync-company-brain.sh" --path "…"` |

Re-run the sync whenever the company brain has been updated. Better still, set up automatic
syncing (a `SessionStart` hook that runs the share's `Auto-Sync` wrapper) so every session
starts current — see `MACHINE SETUP CHECKLIST.md` in the company brain.

## How your own work is protected

A manifest (`~/.claude/.company-brain-manifest`) records exactly which skills and agents came
from the company brain. Because of it:

- **Your local skills and agents are never modified or deleted** — syncing only ever touches
  items listed in the manifest.
- **Name clashes are skipped and reported** — if you have a skill with the same name as a
  company one, *yours wins* and the company version is ignored.
- **Items removed from the company brain are cleaned up** on the next sync, so you don't
  accumulate stale copies.
- **`-Remove` only removes company items**, leaving everything you made in place.

## Why copies rather than links

Windows directory *junctions* can't point at a network (UNC) path, and directory *symlinks*
need administrator rights. Copying avoids both problems, and has a useful side effect: the
company skills still work when you're offline or off the VPN. The trade-off is that you must
re-run the sync to pick up company changes.

## Where Claude looks

The sync writes a small managed block into your user-level `~/.claude/CLAUDE.md` recording
the company brain location, so Claude knows where to find `clients/` and `requirements/` in
any project. Only that marked block is touched — anything else in that file is left alone.

> **Client data stays on the share.** Don't copy it into a project folder or a Git repo.
