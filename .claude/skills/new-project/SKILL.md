---
name: new-project
description: >-
  Set up a new project in this AI Brain workspace. Use this whenever the user
  wants to create, start, scaffold, or add a new project — e.g. "new project",
  "start a project", "set up a site", "spin up a holding page", "add a project
  called X" — even if they don't name the scripts. Prompts for the project name
  and where its files should live, then creates projects/<name> as a real local
  folder — linking any folder the user provides in as files/ inside it, so the
  project folder stays local while the working files stay where they are — and
  scaffolds a standard starter (index + assets/ + README) for brand-new projects.
---

# New project setup

Create a new project in this workspace the way the repo expects: reachable at
`projects/<name>`, with the working files living wherever the user wants, and
(for a brand-new project) scaffolded with the standard starter files.

**`projects/<name>` is always a real local folder.** When the user gives a folder
for the working files, that folder is *not* mounted as `projects/<name>` itself —
it is linked in **inside** the project folder, as `files`:

```
projects/<name>/                          ← real local folder (this is the project)
├── README.md                             ← project notes, kept local
└── files  ->  C:\…\plugins\<name>        ← link to the working files (remote)
```

That keeps the project's own notes, briefs and working documents local to the
workspace, while the code stays in its real home — a Local Sites folder, a client
directory, another drive — and is still reachable at `projects/<name>/files`.

`Set-Project.ps1` / `set-project.sh` still exist and still work, but they mount a
whole project *as* `projects/<name>` — the older model, and some existing projects
are still set up that way. Use them only when the user explicitly asks for that
shape; new projects follow the local folder + `files` link above. `PROJECTS.md`
documents both.

## Step 1 — Gather the two inputs

You need a **name** and a **location**. If the user hasn't given both, ask
(AskUserQuestion is ideal). Don't guess silently.

- **Name** — becomes `projects/<name>`. Normalise to `kebab-case`
  (`efp-services-holding-page`, not `EFP Services`). Confirm the normalised name
  if you changed what the user typed.
- **Location** — where the *working files* live. Offer these choices:
  1. **In the workspace** (default) — the files sit directly in
     `projects/<name>`, no link at all. Simplest; good for most new sites and
     holding pages.
  2. **A specific folder elsewhere on this PC** — e.g. another drive, a client
     directory, or a Local Sites WordPress folder. Linked in as
     `projects/<name>/files`.
  3. **An existing folder** (already has code, e.g. a plugin or a site) — linked
     in as `projects/<name>/files` without scaffolding, so nothing existing is
     touched.

Also capture a one-line description for the README (ask, or infer and confirm).

## Step 2 — Make sure `projects/` exists

Every project lives under it, and the setup scripts refuse to run without it. If
`projects/` is missing, create it first (this just makes a plain in-repo folder):

```powershell
# Windows
.\Set-ProjectsFolder.ps1
```
```bash
# macOS/Linux
./set-projects-folder.sh
```

## Step 3 — Create the project folder (and the `files` link)

`projects/<name>` is a plain local folder in every case — create it first:

```powershell
New-Item -ItemType Directory -Path "projects\<name>" -Force | Out-Null
```
```bash
mkdir -p "projects/<name>"
```

**Choice 1 — in the workspace:** that's all. There is no link; the working files
go straight into `projects/<name>`.

**Choice 2 (new external folder) or Choice 3 (existing folder):** link that folder
in as `files` inside the project folder. Create the target first if it doesn't
exist yet, so the link never points at nothing:

```powershell
# Windows - directory junction, no admin rights needed
$target = "<full path>"
if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory -Path $target | Out-Null }
New-Item -ItemType Junction -Path "projects\<name>\files" -Target $target | Out-Null
```
```bash
# macOS/Linux - symbolic link
mkdir -p "<full path>"
ln -s "<full path>" "projects/<name>/files"
```

Quote paths with spaces. For Choice 3 the path points at the **existing** folder;
linking never moves, copies or overwrites anything there.

If `projects/<name>/files` already exists, stop and check what it is before doing
anything. Re-point an existing link only when that is clearly what the user
wants, and never delete a real folder sitting at that name.

Keep the link named **`files`** so every project has the same shape and paths stay
predictable. Use a different name only if the user asks for one.

## Step 4 — Scaffold (only into an empty or newly created folder)

There are two targets now:

- The **project folder** (`projects/<name>`) is new and local, so it always gets
  `README.md` — it's the project's own note, and it stops the folder being empty.
- The **working files folder** (`projects/<name>` itself for Choice 1, or the link
  target for Choices 2 and 3) gets the code starter, and only when it is safe to
  write into.

The decision to add the starter ("framework") files is driven by the **state of
the working files folder**, never by which location choice the user picked — a
folder they called "new" might already hold real code. Before writing anything,
resolve that folder for real (following the `files` junction/symlink to its true
location) and branch on its state:

- **Folder does not exist** → attempt to create it (including its `assets/`
  subfolder), then add the starter files. If it can't be created, stop and report
  the error rather than continuing.
- **Folder exists and is empty** → add the starter files.
- **Folder exists and is not empty** → **do not copy any starter files.** Treat it
  as existing work and leave every file untouched. Report that it was linked
  as-is and scaffolding was skipped. (The local `README.md` is still written.)

Check emptiness for real (list the folder), don't infer it. "Empty" means no
files or subfolders of any kind.

When you do scaffold, make sure the working folder's `assets/` subfolder exists
first (copying a file into a missing subfolder fails), then copy the starter
files from this skill's `assets/`:

- `README.md`   →  `projects/<name>/README.md`  ← always, and always local
- `index.html`  →  `<working files>/index.html`
- `styles.css`  →  `<working files>/assets/styles.css`
- `main.js`     →  `<working files>/assets/main.js`

For Choice 1 `<working files>` *is* `projects/<name>`, so everything lands in the
one folder. For Choices 2 and 3 write through the link
(`projects/<name>/files/index.html`) or to the real path directly.

Then replace the placeholders in the copied files:

- `{{PROJECT_TITLE}}` → a human-readable title (e.g. "EFP Services").
- `{{PROJECT_ONE_LINER}}` → the one-line description from Step 1.

When the code lives behind the `files` link, say so in the README's structure
section (e.g. "`files/` — link to the working files at `<real path>`") so anyone
opening the project folder can see where the code actually is.

The starter already follows the **coding** skill (semantic HTML5, one `<h1>`,
viewport + `lang`, mobile-first CSS with light/dark support, vanilla JS,
separated concerns). Invoke that skill when writing the scaffold, and adjust it
to fit the actual project rather than leaving boilerplate — but keep those
standards.

If the project clearly isn't a static site (e.g. it's a PHP/WordPress thing),
scaffold the equivalent sensible entry point instead of `index.html`, still with
`assets/` and the local `README.md`, and follow the PHP rules in the **coding**
skill (plus **wordpress-development** for WordPress work).

## Step 5 — Verify and report

Check that the folder is real, the link resolves, and the files are where you
expect:

```powershell
# Windows
Get-ChildItem -LiteralPath "projects\<name>" -Force
Get-Item -LiteralPath "projects\<name>\files" -Force | Select-Object Name, LinkType, Target
Get-ChildItem -LiteralPath "projects\<name>\files" -Force   # reaches the real folder
```
```bash
# macOS/Linux
ls -la "projects/<name>"
ls -la "projects/<name>/files/"
```

`Set-Project.ps1` / `set-project.sh` with no arguments still list every project,
but one built this way shows as "(in workspace)" — because it *is* a real local
folder. Its link is one level down, so check that as above.

Report back concisely:

- the project name, and where the working files really live (in-workspace, or the
  path behind `files`);
- what was scaffolded (or that an existing folder was linked untouched);
- how to open it — `projects/<name>/index.html`, `projects/<name>/files/…`, or the
  project's own entry point.

Remember `projects/` is Git-ignored, so nothing here is committed to the AI Brain
repo — no need to offer a commit for the new project's files.
