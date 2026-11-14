# Cross-platform no-network tests for the reversible ARK Command Deck installer.
# All paths disposable; never touches the actual shell profile or Terminal settings.
$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot 'Install-ARKCommandDeck.ps1'
$fragmentSource = Join-Path $PSScriptRoot 'ARK-Deepwater.fragment.json'
$promptSource = Join-Path $PSScriptRoot 'ARK-CommandDeck.ps1'
if (-not (Test-Path $src) -or -not (Test-Path $fragmentSource) -or -not (Test-Path $promptSource)) {
    throw 'Missing ARK theme source inputs.'
}
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("ark-theme-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp -Force | Out-Null
try {
    $profilePath = Join-Path $temp 'profile/Microsoft.PowerShell_profile.ps1'
    $fragments = Join-Path $temp 'fragments'
    $install = Join-Path $temp 'install'
    New-Item -ItemType Directory -Path (Split-Path $profilePath) -Force | Out-Null
    $preexisting = @'
# Existing customer profile
function existing_ark_test { 'KEEP' }
'@
    Set-Content -LiteralPath $profilePath -Value $preexisting -Encoding utf8

    & $src -ProfilePath $profilePath -FragmentsRoot $fragments -InstallRoot $install
    if (Test-Path -LiteralPath (Join-Path $install 'ARK-CommandDeck.ps1')) {
        throw 'Preview mode wrote theme unexpectedly.'
    }
    & $src -Apply -ProfilePath $profilePath -FragmentsRoot $fragments -InstallRoot $install
    $installedPrompt = Join-Path $install 'ARK-CommandDeck.ps1'
    $installedFragment = Join-Path (Join-Path $fragments 'ARK-Themeing') 'ARK-Deepwater.json'
    if (-not (Test-Path -LiteralPath $installedPrompt) -or -not (Test-Path -LiteralPath $installedFragment)) {
        throw 'Apply did not install both files.'
    }

    $profiles = Get-Content -LiteralPath $installedFragment -Raw | ConvertFrom-Json
    if ($profiles.profiles.Count -ne 1 -or $profiles.profiles[0].name -ne '⚓ ARK Tender') {
        throw 'Terminal fragment lacks expected ARK profile.'
    }
    $profileText = Get-Content -LiteralPath $profilePath -Raw
    if ($profileText -notmatch [regex]::Escape('function existing_ark_test')) {
        throw 'Preexisting user profile content was lost.'
    }
    $marker = '# >>> ARK THEMEING COMMAND DECK >>>'
    if (($profileText.Split([string[]]@($marker), [StringSplitOptions]::None).Length - 1) -ne 1) {
        throw 'ARK profile marker not installed exactly once.'
    }

    & $src -Apply -ProfilePath $profilePath -FragmentsRoot $fragments -InstallRoot $install
    $profileText = Get-Content -LiteralPath $profilePath -Raw
    if (($profileText.Split([string[]]@($marker), [StringSplitOptions]::None).Length - 1) -ne 1) {
        throw 'Repeated Apply duplicated the profile hook.'
    }

    . $installedPrompt
    if (-not (Get-Command prompt -CommandType Function)) {
        throw 'ARK prompt was not installed as a PowerShell function.'
    }
    $env:ARK_POST = 'Tender'
    $env:ARK_PROMPT_MODE = 'expert'
    $global:LASTEXITCODE = 17
    $returned = prompt
    if ($returned -ne ' > ') {
        throw 'Expert prompt returned unexpected marker.'
    }
    if ($global:LASTEXITCODE -ne 17) {
        throw 'Prompt incorrectly changed LASTEXITCODE.'
    }
    Remove-Item Env:ARK_POST, Env:ARK_PROMPT_MODE -ErrorAction SilentlyContinue

    & $src -Remove -ProfilePath $profilePath -FragmentsRoot $fragments -InstallRoot $install
    if ((Test-Path -LiteralPath $installedPrompt) -or (Test-Path -LiteralPath $installedFragment)) {
        throw 'Remove left unchanged ARK theme files installed.'
    }
    $final = Get-Content -LiteralPath $profilePath -Raw
    if ($final -notmatch 'function existing_ark_test' -or $final -match 'ARK THEMEING COMMAND DECK') {
        throw 'Remove did not preserve unrelated profile content.'
    }
    Write-Host 'PASS: preview, opt-in apply, fragment, profile preservation, prompt, idempotence, rollback.'
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
