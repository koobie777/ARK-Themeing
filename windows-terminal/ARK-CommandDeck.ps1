# ARK Command Deck prompt for PowerShell 7
# Standalone: no font, Starship, Oh My Posh, API, network, Git, or elevation required.
# Opt-in: dot-source this script from the user's PowerShell 7 profile.
Set-StrictMode -Version Latest

function global:prompt {
    # Preserve external program exit code; a prompt should not change command results.
    $lastNativeExitCode = $global:LASTEXITCODE
    $path = $executionContext.SessionState.Path.CurrentLocation.Path

    if ($env:ARK_PROMPT_MODE -eq 'expert') {
        Write-Host '⚓ ' -NoNewline -ForegroundColor Cyan
        Write-Host $path -NoNewline -ForegroundColor DarkCyan
        $global:LASTEXITCODE = $lastNativeExitCode
        return ' > '
    }

    $post = if ($env:ARK_POST) { $env:ARK_POST.ToUpperInvariant() } else { 'TENDER' }
    # Don't interpolate untrusted host strings into PowerShell code or file paths.
    $post = $post -replace '[^A-Z0-9_-]', ''
    if ($post.Length -gt 16) { $post = $post.Substring(0, 16) }
    if (-not $post) { $post = 'ARK' }

    Write-Host '╭─⚓ ARK ' -NoNewline -ForegroundColor Cyan
    Write-Host $post -NoNewline -ForegroundColor White
    Write-Host ' ' -NoNewline
    Write-Host $path -ForegroundColor DarkCyan
    Write-Host '╰─❯' -NoNewline -ForegroundColor Cyan

    $global:LASTEXITCODE = $lastNativeExitCode
    return ' '
}
