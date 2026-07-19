<#
.SYNOPSIS
    Sync the company-wide "brain" (skills + agents) into your user-level Claude setup.

.DESCRIPTION
    This workspace uses a two-tier brain:

      * LOCAL   - skills and agents you manage yourself, in this workspace's .claude folder.
                  They only apply while you work here, and they live in this Git repo.
      * COMPANY - shared skills and agents from a company folder (usually a network share),
                  copied into your user-level .claude folder so they work in EVERY project.

    Company items are COPIED, not linked: Windows junctions cannot point at a network (UNC)
    path, and directory symlinks need administrator rights. Copying also means the company
    skills keep working when you are offline or off the VPN. Re-run this script to pick up
    company updates.

    A manifest records exactly which items came from the company brain, so a sync only ever
    updates or removes COMPANY items - skills and agents you created yourself are never
    touched, and a name clash is skipped with a warning (your local copy wins).

    Client data and requirements are NOT copied - they are read in place from the share.
    The company brain location is written into your user-level CLAUDE.md so Claude knows
    where to find them in any project.

    Expected layout of the company brain folder:

        <CompanyBrain>\
            skills\<skill-name>\SKILL.md
            agents\<agent-name>.md
            clients\
            requirements\

.PARAMETER Path
    The company brain folder, e.g. \\server\share\CompanyBrain
    Only needed the first time - it is remembered afterwards.

.PARAMETER Status
    Show the configured company brain and everything currently synced from it.

.PARAMETER Remove
    Remove everything previously synced from the company brain. Your own local skills and
    agents are left alone.

.EXAMPLE
    .\Sync-CompanyBrain.ps1 -Path "\\server\share\CompanyBrain"
    First-time setup: point at the share and sync.

.EXAMPLE
    .\Sync-CompanyBrain.ps1
    Re-sync to pick up company updates.

.EXAMPLE
    .\Sync-CompanyBrain.ps1 -Status
#>
[CmdletBinding()]
param(
    [string]$Path,
    [switch]$Status,
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

$claudeHome = Join-Path $env:USERPROFILE '.claude'
$skillsDir  = Join-Path $claudeHome 'skills'
$agentsDir  = Join-Path $claudeHome 'agents'
$manifest   = Join-Path $claudeHome '.company-brain-manifest'
$userMemory = Join-Path $claudeHome 'CLAUDE.md'

$blockBegin = '<!-- BEGIN company-brain (managed by Sync-CompanyBrain) -->'
$blockEnd   = '<!-- END company-brain -->'

function Read-Manifest {
    $info = [pscustomobject]@{ Path = ''; Skills = @(); Agents = @() }
    if (-not (Test-Path -LiteralPath $manifest)) { return $info }
    $s = @(); $a = @()
    foreach ($line in (Get-Content -LiteralPath $manifest)) {
        if ($line -match '^path=(.*)$')       { $info.Path = $Matches[1] }
        elseif ($line -match '^skill=(.*)$')  { $s += $Matches[1] }
        elseif ($line -match '^agent=(.*)$')  { $a += $Matches[1] }
    }
    $info.Skills = $s
    $info.Agents = $a
    return $info
}

function Write-Manifest($companyPath, $skills, $agents) {
    $lines = @("path=$companyPath")
    foreach ($s in $skills) { $lines += "skill=$s" }
    foreach ($a in $agents) { $lines += "agent=$a" }
    Set-Content -LiteralPath $manifest -Value $lines -Encoding UTF8
}

function Update-UserMemory($companyPath, $refFolders) {
    $text = ''
    if (Test-Path -LiteralPath $userMemory) {
        $text = Get-Content -LiteralPath $userMemory -Raw
        if ($null -eq $text) { $text = '' }
    }
    # Strip any previously managed block, leaving the rest of the file alone.
    $pattern = [regex]::Escape($blockBegin) + '(?s).*?' + [regex]::Escape($blockEnd)
    $text = [regex]::Replace($text, $pattern, '')
    $text = $text.TrimEnd()

    if (-not [string]::IsNullOrWhiteSpace($companyPath)) {
        $refLine = '- No extra reference folders on the share yet.'
        if ($null -ne $refFolders -and $refFolders.Count -gt 0) {
            $refLine = '- Reference material on the share, read it IN PLACE: ' + ($refFolders -join ', ')
        }
        $template = @'
{0}
## Company brain

Shared company knowledge lives at: {1}

- Company **skills** and **agents** from there are synced into your user-level .claude
  folder, so they are available in every project.
{3}
- Never copy client data or company reference material into a project folder or a Git repo.
- Re-sync with Sync-CompanyBrain.ps1 (Windows) or sync-company-brain.sh (macOS/Linux).
{2}
'@
        $block = [string]::Format($template, $blockBegin, $companyPath, $blockEnd, $refLine)
        if ([string]::IsNullOrWhiteSpace($text)) { $text = $block }
        else { $text = $text + "`r`n`r`n" + $block }
    }

    if ([string]::IsNullOrWhiteSpace($text)) {
        if (Test-Path -LiteralPath $userMemory) { Remove-Item -LiteralPath $userMemory -Force }
    }
    else {
        New-Item -ItemType Directory -Path $claudeHome -Force | Out-Null
        Set-Content -LiteralPath $userMemory -Value $text -Encoding UTF8
    }
}

$prev = Read-Manifest

# --- Status -------------------------------------------------------------------
if ($Status) {
    if ([string]::IsNullOrWhiteSpace($prev.Path)) {
        Write-Host "No company brain configured yet."
        Write-Host "Set it up with:  .\Sync-CompanyBrain.ps1 -Path '\\server\share\CompanyBrain'"
        return
    }
    Write-Host "Company brain:  $($prev.Path)"
    Write-Host ("Reachable now:  {0}" -f (Test-Path -LiteralPath $prev.Path))
    Write-Host ""
    Write-Host ("Synced skills ({0}):" -f $prev.Skills.Count)
    foreach ($s in $prev.Skills) { Write-Host "  $s" }
    Write-Host ("Synced agents ({0}):" -f $prev.Agents.Count)
    foreach ($a in $prev.Agents) { Write-Host "  $a" }
    return
}

# --- Remove everything company-sourced ----------------------------------------
if ($Remove) {
    foreach ($s in $prev.Skills) {
        $t = Join-Path $skillsDir $s
        if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Recurse -Force }
    }
    foreach ($a in $prev.Agents) {
        $t = Join-Path $agentsDir $a
        if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Force }
    }
    if (Test-Path -LiteralPath $manifest) { Remove-Item -LiteralPath $manifest -Force }
    Update-UserMemory $null
    Write-Host "Removed all company-synced skills and agents. Your own local ones are untouched."
    return
}

# --- Sync ---------------------------------------------------------------------
$company = $Path
if ([string]::IsNullOrWhiteSpace($company)) { $company = $prev.Path }
if ([string]::IsNullOrWhiteSpace($company)) {
    throw "No company brain path set yet. Run once with:  -Path '\\server\share\CompanyBrain'"
}
if (-not (Test-Path -LiteralPath $company)) {
    throw "Cannot reach the company brain at: $company`r`nCheck the network share is available and you are signed in."
}

New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
New-Item -ItemType Directory -Path $agentsDir -Force | Out-Null

$srcSkills = Join-Path $company 'skills'
$srcAgents = Join-Path $company 'agents'

$newSkills = @()
$newAgents = @()
$skipped   = @()

# Skills: each subfolder containing a SKILL.md
if (Test-Path -LiteralPath $srcSkills) {
    foreach ($dir in (Get-ChildItem -LiteralPath $srcSkills -Directory)) {
        if (-not (Test-Path -LiteralPath (Join-Path $dir.FullName 'SKILL.md'))) { continue }
        $name   = $dir.Name
        $target = Join-Path $skillsDir $name
        if ((Test-Path -LiteralPath $target) -and ($prev.Skills -notcontains $name)) {
            $skipped += "skill '$name' - you already have a local skill with that name"
            continue
        }
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
        Copy-Item -LiteralPath $dir.FullName -Destination $target -Recurse -Force
        $newSkills += $name
    }
}

# Agents: each .md file
if (Test-Path -LiteralPath $srcAgents) {
    foreach ($file in (Get-ChildItem -LiteralPath $srcAgents -Filter '*.md' -File)) {
        $name   = $file.Name
        $target = Join-Path $agentsDir $name
        if ((Test-Path -LiteralPath $target) -and ($prev.Agents -notcontains $name)) {
            $skipped += "agent '$name' - you already have a local agent with that name"
            continue
        }
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        $newAgents += $name
    }
}

# Prune items that have gone from the company brain (company items only)
foreach ($s in $prev.Skills) {
    if ($newSkills -notcontains $s) {
        $t = Join-Path $skillsDir $s
        if (Test-Path -LiteralPath $t) {
            Remove-Item -LiteralPath $t -Recurse -Force
            Write-Host "Removed (no longer in company brain): skill $s"
        }
    }
}
foreach ($a in $prev.Agents) {
    if ($newAgents -notcontains $a) {
        $t = Join-Path $agentsDir $a
        if (Test-Path -LiteralPath $t) {
            Remove-Item -LiteralPath $t -Force
            Write-Host "Removed (no longer in company brain): agent $a"
        }
    }
}

# Any folder other than skills/agents is reference material, read in place (not copied)
$refFolders = @()
foreach ($d in (Get-ChildItem -LiteralPath $company -Directory -ErrorAction SilentlyContinue)) {
    if ($d.Name -ne 'skills' -and $d.Name -ne 'agents') { $refFolders += $d.Name }
}

Write-Manifest $company $newSkills $newAgents
Update-UserMemory $company $refFolders

Write-Host "Company brain:  $company"
Write-Host ("Synced {0} skill(s) and {1} agent(s) into {2}" -f $newSkills.Count, $newAgents.Count, $claudeHome)
foreach ($s in $newSkills) { Write-Host "  skill  $s" }
foreach ($a in $newAgents) { Write-Host "  agent  $a" }
if ($skipped.Count -gt 0) {
    Write-Host ""
    Write-Host "Skipped (your local copy wins):"
    foreach ($k in $skipped) { Write-Host "  $k" }
}
Write-Host ""
Write-Host "Client data and requirements are read in place from the share - they are not copied."
