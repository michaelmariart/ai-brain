---
name: new-project
description: >-
  Set up a new project in this AI Brain workspace. Use this whenever the user
  wants to create, start, scaffold, or add a new project — e.g. "new project",
  "start a project", "set up a site", "spin up a holding page", "add a project
  called X" — even if they don't name the scripts. Prompts for the project name
  and where its files should live, then uses the workspace project-setup scripts
  (Set-Project.ps1 on Windows, set-project.sh on macOS/Linux) to create or link
  it under projects/<name>, and scaffolds a standard starter (index + assets/ +
  README) for brand-new projects.
---

# New project setup

Create a new project in this workspace the way the repo expects: reachable at
`projects/<name>`, physically living wherever the user wants, and (for a
brand-new project) scaffolded with the standard starter files.

The workspace already ships two tools that do the actual folder/link work — this
skill drives them; it does not reinvent them:

- **`Set-Project.ps1`** (Windows, directory junctions)
- **`set-project.sh`** (macOS/Linux, symbolic links)

Both create the target folder if it's missing and link it in under
`projects/<name>`. See `PROJECTS.md` for the full model.

## Step 1 — Gather the two inputs

You need a **name** and a **location**. If the user hasn't given both, ask
(AskUserQuestion is ideal). Don't guess silently.

- **Name** — becomes `projects/<name>`. Normalise to `kebab-case`
  (`efp-services-holding-page`, not `EFP Services`). Confirm the normalised name
  if you changed what the user typed.
- **Location** — offer these choices:
  1. **In the workspace** (default) — lives at `projects/<name>` as a plain
     folder. Simplest; good for most new sites and holding pages.
  2. **A specific folder elsewhere on this PC** — e.g. another drive, a client
     directory, or a Local Sites WordPress folder. Gets linked in.
  3. **Link an existing folder** (already has code, e.g. a plugin) — link it in
     without scaffolding, so nothing existing is touched.

Also capture a one-line description for the README (ask, or infer and confirm).

## Step 2 — Make sure `projects/` exists

The setup scripts refuse to run without it. If `projects/` is missing, create it
first (this just makes a plain in-repo folder):

```powershell
# Windows
.\Set-ProjectsFolder.ps1
```
```bash
# macOS/Linux
./set-projects-folder.sh
```

## Step 3 — Create or link the project

Pick the command by the OS you're running on (this environment's platform is in
your system context) and by the location choice from Step 1.

**Choice 1 — in the workspace:** the setup script's job is *linking elsewhere*,
so an in-workspace project is simply a real subfolder. Create it directly:

```powershell
New-Item -ItemType Directory -Path "projects\<name>" | Out-Null
```
```bash
mkdir -p "projects/<name>"
```

**Choice 2 (new external folder) or Choice 3 (existing folder):** use the setup
script — it creates the folder if needed and links it in:

```powershell
# Windows
.\Set-Project.ps1 -Name <name> -Path "<full path>"
```
```bash
# macOS/Linux
./set-project.sh --name <name> --path "<full path>"
```

Quote paths with spaces. For Choice 3 the path points at the **existing** folder;
the script links it (nothing is moved or overwritten).

## Step 4 — Scaffold (only into an empty or newly created folder)

The decision to add the starter ("framework") files is driven by the **state of
the target folder**, never by which location choice the user picked — a folder
they called "new" might already hold real code. Before writing anything, resolve
the project's real folder (`projects/<name>`, following the junction/symlink to
its true location for linked projects) and branch on its state:

- **Folder does not exist** → attempt to create it (including its `assets/`
  subfolder), then add the starter files. If it can't be created, stop and report
  the error rather than continuing.
- **Folder exists and is empty** → add the starter files.
- **Folder exists and is not empty** → **do not copy any starter files.** Treat it
  as an existing project and leave every file untouched. Report that it was linked
  as-is and scaffolding was skipped.

Check emptiness for real (list the folder), don't infer it. "Empty" means no
files or subfolders of any kind.

When you do scaffold, make sure `projects/<name>/assets/` exists first (copying a
file into a missing subfolder fails), then copy the starter files from this
skill's `assets/` into `projects/<name>/`:

- `index.html`  →  `projects/<name>/index.html`
- `README.md`   →  `projects/<name>/README.md`
- `styles.css`  →  `projects/<name>/assets/styles.css`
- `main.js`     →  `projects/<name>/assets/main.js`

Then replace the placeholders in the copied files:

- `{{PROJECT_TITLE}}` → a human-readable title (e.g. "EFP Services").
- `{{PROJECT_ONE_LINER}}` → the one-line description from Step 1.

The starter already follows the **coding** skill (semantic HTML5, one `<h1>`,
viewport + `lang`, mobile-first CSS with light/dark support, vanilla JS,
separated concerns). Invoke that skill when writing the scaffold, and adjust it
to fit the actual project rather than leaving boilerplate — but keep those
standards.

If the project clearly isn't a static site (e.g. it's a PHP/WordPress thing),
scaffold the equivalent sensible entry point instead of `index.html`, still with
`assets/` and `README.md`, and follow the PHP rules in the **coding** skill
(plus **wordpress-development** for WordPress work).

## Step 5 — Verify and report

Confirm the result with the setup script's own listing, then eyeball the files:

```powershell
.\Set-Project.ps1          # Windows: lists every project and where it lives
```
```bash
./set-project.sh           # macOS/Linux
```

Report back concisely:

- the project name and its real location (in-workspace, or the linked path);
- what was scaffolded (or that an existing folder was linked untouched);
- how to open it — `projects/<name>/index.html`, or the project's own entry point.

Remember `projects/` is Git-ignored, so nothing here is committed to the AI Brain
repo — no need to offer a commit for the new project's files.
