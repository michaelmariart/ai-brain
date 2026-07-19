# AI Brain — Working Conventions

This file is read automatically by Claude Code. It applies to **all work done in this
workspace**, including every project under `projects/`. When a project already has its own
established style, match that project first and use these as the baseline.

Primary stack: **HTML, CSS, JavaScript, PHP** (mostly small websites and holding pages).

> **Coding standards live in the company `coding` skill.**
> Before writing or editing **any** code in this workspace — creating or changing
> HTML/CSS/JS/PHP, building a page, component, block, plugin or WordPress functionality,
> or scaffolding a new file — invoke the **coding** skill and follow it. It covers
> formatting, general principles, the per-language HTML/CSS/JS/PHP rules, and the
> formatter tooling. For WordPress work also load **wordpress-development**.
> Both come from the company brain — see [COMPANY-BRAIN.md](COMPANY-BRAIN.md). This file
> keeps only the workspace and working conventions below.

---

## 1. Workspace layout

- All hands-on work lives in **`projects/`** (one entry per project). This folder is
  Git-ignored — see [PROJECTS.md](PROJECTS.md).
- A project under `projects/` may be a real subfolder **or a link** (a Windows junction, or
  a symlink on macOS) to a folder elsewhere on the machine — managed by `Set-Project.ps1`
  (Windows) or `set-project.sh` (macOS/Linux). When a project is linked in (e.g. the Mariart
  plugin), treat it as living at its real location — match that codebase's existing
  conventions and preserve its line endings.
- Each project is **self-contained**: its own `index` entry point, `assets/` for
  images/fonts/SVG, and a short `README.md`.
- Use **relative paths** inside a project (`assets/logo.svg`), never absolute local paths
  (`C:\Users\...`).
- Never commit secrets, `node_modules/`, `vendor/`, or build output.

## 1a. Two-tier brain (local + company)

Skills and agents come from two places — see [COMPANY-BRAIN.md](COMPANY-BRAIN.md):

- **Local** — this workspace's `.claude/skills` and `.claude/agents`. Yours, tracked in this
  repo, and only active here.
- **Company** — shared skills and agents synced from the company share into your user-level
  `~/.claude/`, so they apply in every project. Sync with `Sync-CompanyBrain.ps1` (Windows)
  or `sync-company-brain.sh` (macOS/Linux). On a name clash the **local** version wins.
- **Client data** (`clients/`) and **requirements** (`requirements/`) live on the company
  share and are **read in place**. Never copy client data into a project folder, and never
  commit it to a Git repo.

## 2. How to work

- Prefer the **simplest thing that works**. Clarity beats cleverness.
- Keep changes **small and focused**; don't reformat or refactor unrelated code.
- **Verify before declaring done** — open the page/app and check it actually works.
- Ask before anything hard to undo (deleting files, publishing, sending).
- Explain trade-offs briefly; don't over-explain routine work.

## 3. Git

- Commit only when asked. Make **small, logical commits** with clear, imperative messages
  ("Add contact form validation", not "stuff").
- Never commit secrets, dependencies (`vendor/`, `node_modules/`), or build artefacts.
- `projects/` is intentionally ignored — see [PROJECTS.md](PROJECTS.md).
