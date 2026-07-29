<#
.SYNOPSIS
    Install the Mariart plugin auto-sync hook: pushing the plugin from a consuming site
    clone fast-forwards the canonical main Mariart working copy (mariart.local).

.DESCRIPTION
    Direction: site clone -> main. For every CONSUMING clone of the Mariart plugin repo on
    this machine - a Local site's wp-content\plugins\mariart other than the canonical one -
    this installs a pre-push git hook and records where the main copy lives. When you
    'git push' the plugin from that site, the hook fast-forwards the main copy to the same
    commit.

    Git has no client-side post-push hook, so the sync runs at pre-push. Every clone is on
    the one machine, so the destination is fast-forwarded directly from the pushing repo
    (the commits already exist locally), which matches "pull after push" for a successful
    push with no network round-trip.

    The hook only ever FAST-FORWARDS, and only when the main copy is clean and on the target
    branch; otherwise it warns and changes nothing. It writes this git config into each
    consuming repo (local to that repo):
        mariart.sync.target / mariart.sync.branch / mariart.sync.remote

    Nothing here is committed to any repository - git hooks and local git config are
    per-clone. Re-run any time to refresh the hook, and use -Uninstall to remove it.

.PARAMETER Target
    The canonical main Mariart working copy to keep up to date.
    Default: C:\Users\michael\Local Sites\mariart\app\public\wp-content\plugins\mariart

.PARAMETER Source
    One or more consuming clones to wire up. If omitted, every sibling Local site with a
    clone of the same repo is discovered automatically.

.PARAMETER Branch
    Branch to keep in sync. Default: main.

.PARAMETER Remote
    Only sync when pushing to this remote. Default: origin.

.PARAMETER Status
    Show what is currently wired up, and make no changes.

.PARAMETER Uninstall
    Remove the hook and config from the consuming clones.

.PARAMETER Force
    Replace an existing, non-Mariart pre-push hook (otherwise such a repo is skipped).

.EXAMPLE
    .\Install-MariartSync.ps1
    Discover consuming clones and wire them all up.

.EXAMPLE
    .\Install-MariartSync.ps1 -Status

.EXAMPLE
    .\Install-MariartSync.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [string]$Target = 'C:\Users\michael\Local Sites\mariart\app\public\wp-content\plugins\mariart',
    [string[]]$Source,
    [string]$Branch = 'main',
    [string]$Remote = 'origin',
    [switch]$Status,
    [switch]$Uninstall,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$marker   = 'mariart-sync'
$template = Join-Path $PSScriptRoot 'tools\mariart-sync\pre-push.sh'

function Test-GitRepo($path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return $false }
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    git -C $path rev-parse --is-inside-work-tree 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Get-GitDir($repo) {
    $d = git -C $repo rev-parse --absolute-git-dir 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    return $d.Trim()
}

function Get-HookPath($repo) {
    $g = Get-GitDir $repo
    if (-not $g) { return $null }
    return (Join-Path $g 'hooks\pre-push')
}

function Get-Origin($repo) {
    return (git -C $repo config --get remote.origin.url 2>$null)
}

function Format-Url($u) {
    if ([string]::IsNullOrWhiteSpace($u)) { return '' }
    return ($u.Trim().ToLowerInvariant() -replace '\.git$', '' -replace '/+$', '')
}

function Resolve-Real($p) {
    try { return ([System.IO.Path]::GetFullPath($p)).TrimEnd('\').ToLowerInvariant() }
    catch { return $p.ToLowerInvariant() }
}

function Get-LocalSitesRoot($targetPath) {
    $full  = [System.IO.Path]::GetFullPath($targetPath)
    $parts = $full -split '[\\/]'
    for ($i = $parts.Length - 1; $i -ge 0; $i--) {
        if ($parts[$i] -eq 'Local Sites') {
            return ($parts[0..$i] -join '\')
        }
    }
    return $null
}

function Find-Sources($targetPath, $targetOrigin) {
    $root = Get-LocalSitesRoot $targetPath
    if (-not $root -or -not (Test-Path -LiteralPath $root)) { return @() }
    $found = @()
    foreach ($site in (Get-ChildItem -LiteralPath $root -Directory)) {
        $cand = Join-Path $site.FullName 'app\public\wp-content\plugins\mariart'
        if (-not (Test-GitRepo $cand)) { continue }
        if ((Resolve-Real $cand) -eq (Resolve-Real $targetPath)) { continue }
        if ((Format-Url (Get-Origin $cand)) -ne (Format-Url $targetOrigin)) { continue }
        $found += $cand
    }
    return $found
}

function Install-One($src, $targetPath, $branch, $remote, $force) {
    $hook = Get-HookPath $src
    if (-not $hook) { Write-Host ("  SKIP  (no git dir) {0}" -f $src); return }
    $hookDir = Split-Path -Parent $hook
    if (-not (Test-Path -LiteralPath $hookDir)) {
        New-Item -ItemType Directory -Path $hookDir -Force | Out-Null
    }
    if ((Test-Path -LiteralPath $hook) -and -not $force) {
        $existing = Get-Content -LiteralPath $hook -Raw
        if ($existing -notmatch [regex]::Escape($marker)) {
            Write-Host ("  SKIP  {0}" -f $src)
            Write-Host  "        a different pre-push hook already exists; re-run with -Force to replace it."
            return
        }
    }
    # Write the hook with LF endings and no BOM so the shebang works under Git's sh.
    # Strip every CR (not just CRLF pairs) so the result is LF regardless of how the
    # template happens to be stored on disk - some sync tools rewrite it to CRLF.
    $body = (Get-Content -LiteralPath $template -Raw) -replace "`r", ""
    [System.IO.File]::WriteAllText($hook, $body, (New-Object System.Text.UTF8Encoding($false)))

    $targetFwd = ([System.IO.Path]::GetFullPath($targetPath)) -replace '\\', '/'
    git -C $src config mariart.sync.target $targetFwd | Out-Null
    git -C $src config mariart.sync.branch $branch    | Out-Null
    git -C $src config mariart.sync.remote $remote    | Out-Null
    Write-Host ("  OK    {0}" -f $src)
}

function Uninstall-One($src) {
    $hook = Get-HookPath $src
    $removed = $false
    if ($hook -and (Test-Path -LiteralPath $hook)) {
        $existing = Get-Content -LiteralPath $hook -Raw
        if ($existing -match [regex]::Escape($marker)) {
            Remove-Item -LiteralPath $hook -Force
            $removed = $true
        }
    }
    git -C $src config --unset mariart.sync.target 2>$null | Out-Null
    git -C $src config --unset mariart.sync.branch 2>$null | Out-Null
    git -C $src config --unset mariart.sync.remote 2>$null | Out-Null
    if ($removed) { Write-Host ("  REMOVED  {0}" -f $src) }
    else          { Write-Host ("  cleared config (no Mariart hook found)  {0}" -f $src) }
}

function Show-One($src) {
    $hook = Get-HookPath $src
    $installed = $false
    if ($hook -and (Test-Path -LiteralPath $hook)) {
        $installed = ((Get-Content -LiteralPath $hook -Raw) -match [regex]::Escape($marker))
    }
    Write-Host ("  {0}" -f $src)
    Write-Host ("      hook installed : {0}" -f $installed)
    Write-Host ("      target         : {0}" -f (git -C $src config --get mariart.sync.target 2>$null))
    Write-Host ("      branch/remote  : {0} / {1}" -f (git -C $src config --get mariart.sync.branch 2>$null), (git -C $src config --get mariart.sync.remote 2>$null))
}

# --- Main ---------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $template)) {
    throw "Hook template not found: $template"
}
if (-not (Test-GitRepo $Target)) {
    throw "Target is not a git repository: $Target"
}
$targetOrigin = Get-Origin $Target

Write-Host "Mariart plugin sync  (site clone -> main)"
Write-Host ("Main (target): {0}" -f $Target)
Write-Host ("Remote origin: {0}" -f $targetOrigin)
Write-Host ("Branch/remote: {0} / {1}" -f $Branch, $Remote)
Write-Host ""

if ($Source -and $Source.Count -gt 0) {
    $sources = @()
    foreach ($s in $Source) {
        if (Test-GitRepo $s) { $sources += $s }
        else { Write-Host ("  (not a git repo, ignored) {0}" -f $s) }
    }
}
else {
    $sources = Find-Sources $Target $targetOrigin
}

if (-not $sources -or $sources.Count -eq 0) {
    Write-Host "No consuming clones found to wire up."
    Write-Host "(Looked for sibling Local sites with a clone of the same repo.)"
    return
}

if ($Status) {
    Write-Host "Consuming clones:"
    foreach ($s in $sources) { Show-One $s }
    return
}
if ($Uninstall) {
    Write-Host "Removing hook + config from consuming clones:"
    foreach ($s in $sources) { Uninstall-One $s }
    return
}

Write-Host "Wiring up consuming clones:"
foreach ($s in $sources) { Install-One $s $Target $Branch $Remote $Force.IsPresent }
Write-Host ""
Write-Host "Done. Push the plugin from any wired clone and the main copy fast-forwards to match."
