<#
.SYNOPSIS
    Sets up (or relocates) the local "projects" workspace for this repo.

.DESCRIPTION
    All project work lives in a folder called "projects" at the root of this repo.
    That folder is ignored by Git, so nothing you build ends up committed here.

    By default "projects" is a normal folder inside the repo. You can instead point
    it at ANY location on this PC (another drive, a folder outside OneDrive, etc.)
    and it will be linked in as ".\projects" using a Windows directory junction.
    Either way you always open your work through .\projects\ — the location is
    transparent to you and to any tools.

    Junctions do NOT require administrator rights.

.PARAMETER Path
    Optional. A folder anywhere on this PC where the projects should physically live.
    If the folder doesn't exist it is created. If ".\projects" already contains work,
    that work is moved to the new location first. Omit to keep projects inside the repo.

.PARAMETER Status
    Just report where "projects" currently points, then exit.

.EXAMPLE
    .\Set-ProjectsFolder.ps1
    Keep projects inside the repo (the default).

.EXAMPLE
    .\Set-ProjectsFolder.ps1 -Path "D:\AI-Brain-Projects"
    Physically store projects on D:\ ; ".\projects" still opens them.

.EXAMPLE
    .\Set-ProjectsFolder.ps1 -Status
    Show the current location.
#>
[CmdletBinding()]
param(
    [string]$Path,
    [switch]$Status
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$link = Join-Path $repo 'projects'

function Get-Location-Info {
    if (-not (Test-Path -LiteralPath $link)) { return $null }
    $item = Get-Item -LiteralPath $link -Force
    if ($item.LinkType) {
        return [pscustomobject]@{ Kind = $item.LinkType; Location = ($item.Target | Select-Object -First 1) }
    }
    return [pscustomobject]@{ Kind = 'Folder (inside repo)'; Location = $item.FullName }
}

# --- Status only -------------------------------------------------------------
if ($Status) {
    $info = Get-Location-Info
    if ($null -eq $info) {
        Write-Host "No 'projects' folder yet. Run  .\Set-ProjectsFolder.ps1  to create it."
    } else {
        Write-Host ("projects  [{0}]  ->  {1}" -f $info.Kind, $info.Location)
    }
    return
}

# --- 1) Make sure Git ignores the workspace ----------------------------------
$gitignore = Join-Path $repo '.gitignore'
$already = (Test-Path -LiteralPath $gitignore) -and
           (Select-String -LiteralPath $gitignore -SimpleMatch 'projects/' -Quiet)
if (-not $already) {
    $block = "`r`n# Local projects workspace - not tracked; may physically live anywhere on this PC`r`nprojects/`r`n"
    Add-Content -LiteralPath $gitignore -Value $block
    Write-Host "Added 'projects/' to .gitignore"
}

# --- 2a) Relocate to a chosen path -------------------------------------------
if ($Path) {
    $target = [System.IO.Path]::GetFullPath($Path)

    if (-not (Test-Path -LiteralPath $target)) {
        New-Item -ItemType Directory -Path $target | Out-Null
        Write-Host "Created  $target"
    }

    if (Test-Path -LiteralPath $link) {
        $existing = Get-Item -LiteralPath $link -Force
        if ($existing.LinkType) {
            # Already a link -> removing it only removes the link, never the real data
            Remove-Item -LiteralPath $link -Force
        } else {
            # Real folder with work in it -> move that work into the new location
            $children = Get-ChildItem -LiteralPath $link -Force
            foreach ($c in $children) {
                $dest = Join-Path $target $c.Name
                if (Test-Path -LiteralPath $dest) {
                    throw "A folder named '$($c.Name)' already exists in $target. Move or rename it, then re-run."
                }
                Move-Item -LiteralPath $c.FullName -Destination $target
            }
            Remove-Item -LiteralPath $link -Force -Recurse
            if ($children) { Write-Host "Moved existing projects into  $target" }
        }
    }

    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    Write-Host "projects  [Junction]  ->  $target"
}
# --- 2b) Default: a plain folder inside the repo -----------------------------
else {
    $existing = Get-Location-Info
    if ($null -eq $existing) {
        New-Item -ItemType Directory -Path $link | Out-Null
        Write-Host "Created  projects  (folder inside the repo)"
    } elseif ($existing.Kind -like 'Junction*' -or $existing.Kind -like 'Symbolic*') {
        Write-Host ("projects is currently linked to {0}. Leaving it. Pass -Path to change, or delete the link to move back inside the repo." -f $existing.Location)
    } else {
        Write-Host "projects folder already exists inside the repo. Nothing to do."
    }
}

Write-Host ""
Write-Host "Done. Put each project in its own subfolder under  .\projects\"
Write-Host "Check the location any time with:  .\Set-ProjectsFolder.ps1 -Status"
