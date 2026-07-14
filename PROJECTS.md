# Projects workspace

All hands-on project work lives in a **`projects/`** folder at the root of this repo.
That folder is **ignored by Git**, so nothing you build there is ever committed to the
AI Brain repo. Each project gets its own subfolder:

```
AI Brain/
├── projects/                       ← your work lives here (NOT tracked by Git)
│   ├── efp-services-holding-page/  ← a project that lives in the workspace
│   └── mariart  ->  …/plugins/…    ← a project linked in from elsewhere
├── Set-ProjectsFolder.ps1          ← Windows: where the whole workspace lives
├── Set-Project.ps1                 ← Windows: where each individual project lives
├── set-projects-folder.sh          ← macOS/Linux: same as Set-ProjectsFolder.ps1
├── set-project.sh                  ← macOS/Linux: same as Set-Project.ps1
├── PROJECTS.md                     ← this file
├── .gitattributes                  ← keeps the .sh scripts LF so they run on macOS
└── .gitignore                      ← contains the line `projects/`
```

There are two levels of control:

- **the folder tool** (`Set-ProjectsFolder.ps1` / `set-projects-folder.sh`) — moves the
  *entire* `projects/` folder somewhere else.
- **the project tool** (`Set-Project.ps1` / `set-project.sh`) — lets each *individual*
  project live anywhere on the machine, linked in under `projects/<name>`. Projects don't
  have to be centralised in one place.

### Windows and macOS / Linux

The same tools exist for both platforms and behave identically — Windows uses PowerShell
and *directory junctions*; macOS/Linux use shell scripts and *symbolic links*. Neither
needs administrator rights.

| Action | Windows (PowerShell) | macOS / Linux (Terminal) |
|---|---|---|
| List projects | `.\Set-Project.ps1` | `./set-project.sh` |
| Link a folder in | `.\Set-Project.ps1 -Name x -Path "…"` | `./set-project.sh --name x --path "…"` |
| Move a project out | `.\Set-Project.ps1 -Name x -Path "…"` | `./set-project.sh --name x --path "…"` |
| Unlink a project | `.\Set-Project.ps1 -Name x -Unlink` | `./set-project.sh --name x --unlink` |
| Relocate whole workspace | `.\Set-ProjectsFolder.ps1 -Path "…"` | `./set-projects-folder.sh --path "…"` |
| Show workspace location | `.\Set-ProjectsFolder.ps1 -Status` | `./set-projects-folder.sh --status` |

> On macOS/Linux the scripts may need to be made executable once: `chmod +x *.sh`
> (then run them as `./set-project.sh`). The examples below use PowerShell; swap in the
> matching command from the table above.

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

## Individual projects in different locations

Each project can physically live wherever suits it — a Local Sites WordPress folder, a
client directory, another drive — and be linked in under `projects/<name>` so you still
reach it at `.\projects\<name>`. Use **`Set-Project.ps1`** for this.

### List every project and where it lives
```powershell
.\Set-Project.ps1
```

### Link an existing folder in (nothing is moved)
```powershell
.\Set-Project.ps1 -Name mariart -Path "C:\Users\me\Local Sites\mariart\app\public\wp-content\plugins\mariart"
```
Great for working on an existing site/plugin through the workspace without copying it.

### Move an in-workspace project out to another location
```powershell
.\Set-Project.ps1 -Name efp-services-holding-page -Path "D:\Work\efp"
```
Moves the project's files to the new location, then links it back in.

### Unlink a project (files are kept)
```powershell
.\Set-Project.ps1 -Name mariart -Unlink
```
Removes only the link — the real folder stays exactly where it is. (The tool refuses to
unlink a real in-workspace folder, so you can't lose data by accident.)

> Linked projects live outside `projects/`, so — like the workspace itself — Git never
> sees or tracks them.

## Why it's set up this way
- **Self-contained:** every project is one tidy entry under `projects/`.
- **Git-clean:** project files never clutter or bloat the tracked repo.
- **Portable:** the whole workspace *and* each individual project can live anywhere on the
  PC without changing how you open your work.
