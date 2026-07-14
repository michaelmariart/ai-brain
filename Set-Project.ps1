<#
.SYNOPSIS
    Manage individual projects - each can physically live anywhere on this PC.

.DESCRIPTION
    Projects are reached through .\projects\<name>. By default a project is a plain
    subfolder there, but ANY project can instead live somewhere else on this PC and be
    linked into .\projects\<name> with a Windows directory junction (no admin needed).

    This means projects do not have to be centralised in one folder - keep each one
    wherever suits (a Local Sites WordPress folder, another drive, a client directory)
    and link it in so Claude and your tools can reach it at .\projects\<name>.

    The junction target lives outside the repo, so - like the projects folder itself -
    nothing linked in is ever tracked by Git.

.PARAMETER Name
    The project name as it appears under .\projects\ (the link/folder name).

.PARAMETER Path
    A folder on this PC for the project. What happens depends on the current state:
      * projects\<Name> does not exist   -> link it to Path (Path is created if missing).
      * projects\<Name> is a real folder -> its contents are MOVED to Path, then linked.
      * projects\<Name> is already a link -> re-pointed to Path (old data left in place).

.PARAMETER Unlink
    Remove the link for projects\<Name>. Only the link is removed - the real files are
    never deleted. Refuses to touch a real (non-linked) folder, to avoid data loss.

.PARAMETER List
    Show every project and where it physically lives. This is the default with no args.

.EXAMPLE
    .\Set-Project.ps1
    List all projects and their locations.

.EXAMPLE
    .\Set-Project.ps1 -Name mariart -Path "C:\Users\me\Local Sites\mariart\app\public\wp-content\plugins\mariart"
    Link an existing folder (e.g. a WordPress plugin) in as projects\mariart.

.EXAMPLE
    .\Set-Project.ps1 -Name efp-services-holding-page -Path "D:\Work\efp"
    Move an existing in-workspace project out to another drive, still reachable as projects\...

.EXAMPLE
    .\Set-Project.ps1 -Name mariart -Unlink
    Remove the link (the real plugin folder is left exactly where it is).
#>
[CmdletBinding()]
param(
    [string]$Name,
    [string]$Path,
    [switch]$Unlink,
    [switch]$List
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$projects = Join-Path $repo 'projects'

if (-not (Test-Path -LiteralPath $projects)) {
    throw "No 'projects' folder yet. Run  .\Set-ProjectsFolder.ps1  first."
}

function Remove-Junction([string]$linkPath) {
    # Removes ONLY the junction (reparse point) - never follows it or deletes the
    # target's contents. Remove-Item is unsafe on junctions (can prompt, or recurse
    # into the target on older PowerShell), so use the .NET call instead.
    [System.IO.Directory]::Delete($linkPath)
}

function Show-Projects {
    $items = Get-ChildItem -LiteralPath $projects -Directory -Force | Sort-Object Name
    if (-not $items) {
        Write-Host "  (no projects yet)"
        return
    }
    foreach ($it in $items) {
        if ($it.LinkType) {
            $target = ($it.Target | Select-Object -First 1)
            Write-Host ("  {0,-34} ->  {1}" -f $it.Name, $target)
        }
        else {
            Write-Host ("  {0,-34}     (in workspace)" -f $it.Name)
        }
    }
}

# --- List (explicit, or when nothing else is asked for) ----------------------
if ($List -or (-not $Name -and -not $Path -and -not $Unlink)) {
    Write-Host "Projects in  $projects"
    Show-Projects
    return
}

$link = Join-Path $projects $Name

# --- Unlink ------------------------------------------------------------------
if ($Unlink) {
    if (-not $Name) { throw "Use  -Name <project>  with -Unlink." }
    if (-not (Test-Path -LiteralPath $link)) { throw "No project named '$Name'." }
    $item = Get-Item -LiteralPath $link -Force
    if (-not $item.LinkType) {
        throw "'$Name' is a real folder in the workspace, not a link. Leaving it alone to avoid data loss. Move or delete it manually if you are sure."
    }
    $where = ($item.Target | Select-Object -First 1)
    Remove-Junction $link
    Write-Host "Unlinked '$Name'. Its files remain at:  $where"
    return
}

# --- Set: link / move / re-point ---------------------------------------------
if (-not $Name -or -not $Path) {
    throw "Usage:  -Name <project> -Path <folder>   |   -List   |   -Unlink -Name <project>"
}

$target = [System.IO.Path]::GetFullPath($Path)

if (-not (Test-Path -LiteralPath $link)) {
    # LINK: point projects\<Name> at Path (create Path if it does not exist yet)
    if (-not (Test-Path -LiteralPath $target)) {
        New-Item -ItemType Directory -Path $target | Out-Null
        Write-Host "Created  $target"
    }
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    Write-Host "Linked   projects\$Name  ->  $target"
}
else {
    $item = Get-Item -LiteralPath $link -Force
    if ($item.LinkType) {
        # RE-POINT: swap an existing link to a new location (old data left in place)
        $old = ($item.Target | Select-Object -First 1)
        if (-not (Test-Path -LiteralPath $target)) {
            New-Item -ItemType Directory -Path $target | Out-Null
        }
        Remove-Junction $link
        New-Item -ItemType Junction -Path $link -Target $target | Out-Null
        Write-Host "Re-pointed  projects\$Name  ->  $target"
        Write-Host "(Old location left untouched:  $old)"
    }
    else {
        # MOVE: relocate a real in-workspace project out to Path, then link it back
        if (-not (Test-Path -LiteralPath $target)) {
            New-Item -ItemType Directory -Path $target | Out-Null
        }
        if (Get-ChildItem -LiteralPath $target -Force) {
            throw "$target is not empty. Choose an empty or new folder to move '$Name' into."
        }
        Get-ChildItem -LiteralPath $link -Force | ForEach-Object {
            Move-Item -LiteralPath $_.FullName -Destination $target
        }
        # $link is now an empty real folder - remove it (non-recursive) before linking
        [System.IO.Directory]::Delete($link)
        New-Item -ItemType Junction -Path $link -Target $target | Out-Null
        Write-Host "Moved    projects\$Name  ->  $target   and linked it back in"
    }
}

Write-Host ""
Write-Host "Projects now:"
Show-Projects
