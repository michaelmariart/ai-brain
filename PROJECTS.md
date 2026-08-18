# Projects workspace

All hands-on project work lives in a **`projects/`** folder at the root of this repo.
That folder is **ignored by Git**, so nothing you build there is ever committed to the
AI Brain repo. Each project gets its own subfolder:

```
AI Brain/
├── projects/                          ← your work lives here (NOT tracked by Git)
│   ├── efp-services-holding-page/     ← a project whose files live in the workspace
│   └── mariart/                       ← a project folder, local…
│       ├── README.md                  ←   …holding its own notes…
│       └── files  ->  …/plugins/…     ←   …and a link to the working files elsewhere
├── Set-ProjectsFolder.ps1             ← Windows: where the whole workspace lives
├── Set-Project.ps1                    ← Windows: mount a whole project from elsewhere
├── set-projects-folder.sh             ← macOS/Linux: same as Set-ProjectsFolder.ps1
├── set-project.sh                     ← macOS/Linux: same as Set-Project.ps1
├── PROJECTS.md                        ← this file
├── .gitattributes                     ← keeps the .sh scripts LF so they run on macOS
└── .gitignore                         ← contains the line `projects/`
```

## How a project is laid out (the default)

**`projects/<name>` is a real local folder.** It is the project: its README, notes,
briefs, working documents — the things that belong to *your* copy of the job.

When the code itself lives somewhere else on this PC — a Local Sites WordPress folder, a
client directory, another drive — that folder is **not** mounted as `projects/<name>`.
It is linked in **inside** the project folder, as **`files`**:

```
projects/mariart/
├── README.md
└── files  ->  C:\Users\me\Local Sites\mariart\app\public\wp-content\plugins\mariart
```

So the project folder is local and the working files stay remote, reached at
`projects/<name>/files`. Keep the link named `files` on every project so paths stay
predictable.

Set it up like this — the folder first, then the link (create the target if it doesn't
exist yet, so the link never points at nothing):

```powershell
# Windows - directory junction, no admin rights needed
New-Item -ItemType Directory -Path "projects\mariart" -Force | Out-Null
New-Item -ItemType Junction -Path "projects\mariart\files" -Target "C:\…\plugins\mariart" | Out-Null
```
```bash
# macOS/Linux - symbolic link
mkdir -p "projects/mariart"
ln -s "/Users/me/…/plugins/mariart" "projects/mariart/files"
```

Nothing is moved, copied or overwritten at the target — linking only points at it.

If a project's files live in the workspace anyway, there's no link at all: `projects/<name>`
is a plain folder with the files straight inside it.

> The **new-project** skill does all of this for you — it asks for the name and where the
> working files should live, creates the folder and the link, and scaffolds the starter
> files. Just ask for a new project.

### Removing a `files` link

Delete only the link, never the target's contents:

```powershell
[System.IO.Directory]::Delete("projects\mariart\files")   # Windows: junction only
```
```bash
rm "projects/mariart/files"                                # macOS/Linux: symlink only
```

## The setup scripts

Two scripts ship with the workspace:

- **the folder tool** (`Set-ProjectsFolder.ps1` / `set-projects-folder.sh`) — moves the
  *entire* `projects/` folder somewhere else.
- **the project tool** (`Set-Project.ps1` / `set-project.sh`) — mounts a whole project
  *as* `projects/<name>`, so the project folder itself is the remote folder. This is the
  older model, kept because some projects were set up that way and still work fine. New
  projects use the local folder + `files` link above.

### Windows and macOS / Linux

The same tools exist for both platforms and behave identically — Windows uses PowerShell
and *directory junctions*; macOS/Linux use shell scripts and *symbolic links*. Neither
needs administrator rights.

| Action | Windows (PowerShell) | macOS / Linux (Terminal) |
|---|---|---|
| List projects | `.\Set-Project.ps1` | `./set-project.sh` |
| Mount a folder as a whole project | `.\Set-Project.ps1 -Name x -Path "…"` | `./set-project.sh --name x --path "…"` |
| Move a project out | `.\Set-Project.ps1 -Name x -Path "…"` | `./set-project.sh --name x --path "…"` |
| Unmount a project | `.\Set-Project.ps1 -Name x -Unlink` | `./set-project.sh --name x --unlink` |
| Relocate whole workspace | `.\Set-ProjectsFolder.ps1 -Path "…"` | `./set-projects-folder.sh --path "…"` |
| Show workspace location | `.\Set-ProjectsFolder.ps1 -Status` | `./set-projects-folder.sh --status` |

> On macOS/Linux the scripts may need to be made executable once: `chmod +x *.sh`
> (then run them as `./set-project.sh`). The examples below use PowerShell; swap in the
> matching command from the table above.

Note that the listing reports a project laid out the default way as **(in workspace)** —
because it *is* a real local folder. Its `files` link is one level down, so check that
directly:

```powershell
Get-Item -LiteralPath "projects\mariart\files" -Force | Select-Object Name, LinkType, Target
```
```bash
ls -la "projects/mariart"
```

## Where the files physically live

By default `projects/` is a normal folder inside this repo. But it can point to **any
location on this machine** — another drive, or a folder outside OneDrive — while you still
open everything through `projects/`. This is done with a Windows *directory junction*
(or a *symbolic link* on macOS/Linux) — no administrator rights needed.

### Move the workspace somewhere else
Open PowerShell in this folder and run:

```powershell
.\Set-ProjectsFolder.ps1 -Path "D:\AI-Brain-Projects"
```

- Creates the folder if it doesn't exist.
- Moves any existing projects into the new location.
- Links it back in as `.\projects\`.

Common reason to do this: keep large projects **out of OneDrive** so they don't sync.

### Check the current location
```powershell
.\Set-ProjectsFolder.ps1 -Status
```

### Move it back inside the repo
Delete the `projects` link (this only removes the link, never your files at the target),
then run `.\Set-ProjectsFolder.ps1` with no arguments to recreate a plain folder — or
just re-point it with `-Path`.

## Mounting a whole project from elsewhere (the older model)

`Set-Project.ps1` makes `projects/<name>` *itself* the link, so the whole project folder
is the remote one — there's nowhere local to keep the project's own notes. Prefer the
default layout for new work; this is here for projects already set up this way.

### List every project and where it lives
```powershell
.\Set-Project.ps1
```

### Mount an existing folder (nothing is moved)
```powershell
.\Set-Project.ps1 -Name mariart -Path "C:\Users\me\Local Sites\mariart\app\public\wp-content\plugins\mariart"
```

### Move an in-workspace project out to another location
```powershell
.\Set-Project.ps1 -Name efp-services-holding-page -Path "D:\Work\efp"
```
Moves the project's files to the new location, then links it back in.

### Unmount a project (files are kept)
```powershell
.\Set-Project.ps1 -Name mariart -Unlink
```
Removes only the link — the real folder stays exactly where it is. (The tool refuses to
unlink a real in-workspace folder, so you can't lose data by accident.)

> Whichever model a project uses, its remote files live outside `projects/` — so, like the
> workspace itself, Git never sees or tracks them.

## Why it's set up this way
- **Self-contained:** every project is one tidy entry under `projects/`.
- **Local where it counts:** the project folder — notes, briefs, working documents — is
  always here in the workspace, even when the code it describes lives elsewhere.
- **Git-clean:** project files never clutter or bloat the tracked repo.
- **Portable:** the whole workspace *and* each individual project can live anywhere on the
  PC without changing how you open your work.
