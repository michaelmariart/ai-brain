# Projects workspace

All hands-on project work lives in a **`projects/`** folder at the root of this repo.
That folder is **ignored by Git**, so nothing you build there is ever committed to the
AI Brain repo. Each project gets its own subfolder:

```
AI Brain/
├── projects/                       ← your work lives here (NOT tracked by Git)
│   └── efp-services-holding-page/  ← one project per subfolder
├── Set-ProjectsFolder.ps1          ← tool that creates / relocates the workspace
├── PROJECTS.md                     ← this file
└── .gitignore                      ← contains the line `projects/`
```

## Where the files physically live

By default `projects/` is a normal folder inside this repo. But it can point to **any
location on this PC** — another drive, or a folder outside OneDrive — while you still
open everything through `.\projects\`. This is done with a Windows *directory junction*
(no administrator rights needed).

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

## Why it's set up this way
- **Self-contained:** every project is one tidy subfolder.
- **Git-clean:** project files never clutter or bloat the tracked repo.
- **Portable:** the physical location can be anywhere on the PC without changing how you
  open your work.
