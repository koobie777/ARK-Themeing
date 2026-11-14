# ⚓ ARK Command Deck — PowerShell 7 + Windows Terminal

**Status:** opt-in review candidate. Not installed merely by merging or cloning this repository. Requires PowerShell 7 and Windows Terminal Stable or Preview.

This module adds an **ARK Deepwater** color scheme and a separate **⚓ ARK Tender** profile to Windows Terminal, plus a lightweight ARK prompt for PowerShell 7. It does not require Oh My Posh, Starship, fonts, admin rights, Tailscale, or AI services.

### No-configuration-changing preview

From a checkout of this branch, in PowerShell 7 (command is `pwsh`):

```powershell
pwsh -NoLogo -NoProfile -File .\windows-terminal\Install-ARKCommandDeck.ps1
```

### Install for current user (after review)

```powershell
pwsh -NoLogo -NoProfile -File .\windows-terminal\Install-ARKCommandDeck.ps1 -Apply
```

Open a **new** Windows Terminal window/tab and select the **⚓ ARK Tender** profile. The original default PowerShell 7 profile remains selected unless you choose otherwise.

The installer adds a short, marked dot-source block to the PowerShell 7 **current-user/current-host** profile and places the actual prompt under `%LOCALAPPDATA%\ARK\Themeing`. It creates a standalone JSON fragment in `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\ARK-Themeing`. This is a supported mechanism that avoids rewriting either Windows Terminal Stable's or Preview's `settings.json`. Current-user profile behavior is based on PowerShell's standard `$PROFILE.CurrentUserCurrentHost`.

### Options

Set `$env:ARK_POST='TENDER'` (or another short fleet post name) for the current PowerShell process. Set `$env:ARK_PROMPT_MODE='expert'` for the compact single-line prompt. These are opt-in session variables; nothing changes ARK Bus or host names.

### Undo without disturbing other profiles

```powershell
pwsh -NoLogo -NoProfile -File .\windows-terminal\Install-ARKCommandDeck.ps1 -Remove
```

This removes the marked profile hook and unchanged ARK-managed fragment/prompt files, retaining backups where modifications were made. If any managed file was customized, the remover leaves it alone. Restart PowerShell to restore the previous active prompt.

### Local test in a disposable directory

```powershell
pwsh -NoLogo -NoProfile -File .\windows-terminal\Test-ARKCommandDeck.ps1
```

GitHub Actions runs this test on **Windows and Ubuntu** with disposable test paths, verifying preview-only mode, install, rollback, no unrelated profile damage, and repeated install idempotence.

### Boundaries

- No edits to Windows Terminal `settings.json`, Windows default terminal application, or other user's profiles.
- No modification of Windows PowerShell 5.1.
- No SSH services, drivers, filesystems, credentials, ARK Bus, or fleet deployments touched.
- No network calls or new external package dependencies.
- Windows Terminal uses the user fragment path documented by Microsoft: https://learn.microsoft.com/en-us/windows/terminal/json-fragment-extensions

**Operator caution:** The “Cairn – Codex” desktop shortcut is a *separate* launcher issue. This theme does not fix a missing Codex runtime or change the shortcut target.
