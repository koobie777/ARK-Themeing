# ARK Themeing: reversible PowerShell 7 / Windows Terminal fragment installer
# Default mode is preview only. Requires explicit -Apply or -Remove to modify files.
[CmdletBinding(DefaultParameterSetName = 'Preview')]
param(
    [Parameter(ParameterSetName = 'Apply')]
    [switch] $Apply,
    [Parameter(ParameterSetName = 'Remove')]
    [switch] $Remove,
    [string] $ProfilePath,
    [string] $FragmentsRoot,
    [string] $InstallRoot
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Run this installer under PowerShell 7, not Windows PowerShell 5.1.'
}

if (-not $ProfilePath) { $ProfilePath = $PROFILE.CurrentUserCurrentHost }
if (-not $FragmentsRoot) {
    if (-not $env:LOCALAPPDATA) { throw 'LOCALAPPDATA is unavailable; pass -FragmentsRoot.' }
    $FragmentsRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments'
}
if (-not $InstallRoot) {
    if (-not $env:LOCALAPPDATA) { throw 'LOCALAPPDATA is unavailable; pass -InstallRoot.' }
    $InstallRoot = Join-Path $env:LOCALAPPDATA 'ARK\Themeing'
}

$sourcePrompt = Join-Path $PSScriptRoot 'ARK-CommandDeck.ps1'
$sourceFragment = Join-Path $PSScriptRoot 'ARK-Deepwater.fragment.json'
$targetPrompt = Join-Path $InstallRoot 'ARK-CommandDeck.ps1'
$fragmentTarget = Join-Path (Join-Path $FragmentsRoot 'ARK-Themeing') 'ARK-Deepwater.json'
$blockStart = '# >>> ARK THEMEING COMMAND DECK >>>'
$blockEnd = '# <<< ARK THEMEING COMMAND DECK <<<'
$quotedTarget = $targetPrompt.Replace("'", "''")
$profileBlock = @(
    $blockStart,
    ". '$quotedTarget'",
    $blockEnd
) -join [Environment]::NewLine

foreach ($file in @($sourcePrompt, $sourceFragment)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw 'Theme source files must be next to this installer.'
    }
}
$fragmentData = Get-Content -LiteralPath $sourceFragment -Raw | ConvertFrom-Json
if ($fragmentData.schemes.Count -ne 1 -or $fragmentData.schemes[0].name -ne 'ARK Deepwater') {
    throw 'Refusing to install an unrecognized color scheme.'
}

function Save-BackupIfExists([string] $Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
        $backup = "$Path.arkbackup-$timestamp"
        Copy-Item -LiteralPath $Path -Destination $backup -ErrorAction Stop
        return $backup
    }
    return $null
}

Write-Host 'ARK Command Deck (current-user scope only)'
Write-Host "PowerShell profile: $ProfilePath"
Write-Host "Theme prompt: $targetPrompt"
Write-Host "Terminal scheme/profile fragment: $fragmentTarget"

if (-not $Apply -and -not $Remove) {
    Write-Host 'PREVIEW ONLY. Use -Apply to install or -Remove to undo.'
    exit 0
}

if ($Remove) {
    # Never remove unrelated profile lines or customized Terminal fragments.
    if (Test-Path -LiteralPath $ProfilePath -PathType Leaf) {
        $current = Get-Content -LiteralPath $ProfilePath -Raw
        $pattern = '(?s)' + [regex]::Escape($blockStart) + '.*?' + [regex]::Escape($blockEnd)
        if ([regex]::IsMatch($current, $pattern)) {
            $null = Save-BackupIfExists $ProfilePath
            $updated = [regex]::Replace($current, $pattern, '').TrimEnd() + [Environment]::NewLine
            Set-Content -LiteralPath $ProfilePath -Value $updated -Encoding utf8NoBOM -NoNewline
            Write-Host 'Removed ARK prompt hook (restart PowerShell to revert active prompt).'
        }
    }
    foreach ($item in @(
        @{ Target = $fragmentTarget; Source = $sourceFragment },
        @{ Target = $targetPrompt; Source = $sourcePrompt }
    )) {
        if (Test-Path -LiteralPath $item.Target -PathType Leaf) {
            $targetHash = (Get-FileHash -LiteralPath $item.Target -Algorithm SHA256).Hash
            $sourceHash = (Get-FileHash -LiteralPath $item.Source -Algorithm SHA256).Hash
            if ($targetHash -eq $sourceHash) {
                Remove-Item -LiteralPath $item.Target -Force
                Write-Host 'Removed an unchanged ARK-managed theme file.'
            }
            else {
                Write-Warning 'A theme file was customized; leaving it untouched.'
            }
        }
    }
    Write-Host 'Removed only ARK-owned configuration. Stable/Preview defaults unchanged.'
    exit 0
}

# Install does not modify Windows Terminal settings.json, default terminal/profile,
# SSH/Bus services, any ARK project, or the Windows PowerShell 5.1 profile.
foreach ($item in @(
    @{ Source = $sourcePrompt; Target = $targetPrompt },
    @{ Source = $sourceFragment; Target = $fragmentTarget }
)) {
    $directory = Split-Path -Parent $item.Target
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $write = $true
    if (Test-Path -LiteralPath $item.Target -PathType Leaf) {
        $write = (Get-FileHash -LiteralPath $item.Target -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $item.Source -Algorithm SHA256).Hash
    }
    if ($write) {
        $null = Save-BackupIfExists $item.Target
        Copy-Item -LiteralPath $item.Source -Destination $item.Target -Force
    }
}

$profileDir = Split-Path -Parent $ProfilePath
New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
$currentProfile = ''
if (Test-Path -LiteralPath $ProfilePath -PathType Leaf) {
    $currentProfile = Get-Content -LiteralPath $ProfilePath -Raw
}
if ($currentProfile -notmatch [regex]::Escape($blockStart)) {
    $null = Save-BackupIfExists $ProfilePath
    $content = $currentProfile.TrimEnd() + [Environment]::NewLine + $profileBlock + [Environment]::NewLine
    Set-Content -LiteralPath $ProfilePath -Value $content -Encoding utf8NoBOM -NoNewline
}
else {
    Write-Host 'Existing ARK profile hook retained; no duplicate added.'
}
Write-Host 'ARK Deepwater installed as a NEW Terminal profile; existing defaults untouched.'
Write-Host 'Open a new Windows Terminal tab named "⚓ ARK Tender".'
