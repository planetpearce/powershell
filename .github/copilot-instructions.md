# PowerShell Profile Environment

This repo is Nick's PowerShell profile and Dev Drive environment bootstrap, hosted on `D:\PowerShell\` (ReFS Dev Drive). The real OS profile (`C:\...\Microsoft.PowerShell_profile.ps1`) is a one-liner stub that dot-sources `_profile.ps1`. See [README.md](../README.md) for full architecture.

---

## Coding Conventions

- **PowerShell 7+ syntax** — do not use legacy Windows PowerShell 5.1 patterns.
- **Do not use `Clear-Host`** inside profile or Init scripts — it wipes earlier terminal output intentionally preserved.
- **Performance comments** (`🏎️ OPTIMIZATION:`) document intentional choices. Preserve them when editing those lines.
- **`$null =` assignments** are preferred over `| Out-Null` pipes for suppressing output in hot paths.
- **No pipeline aliases** in scripts (`gci`/`?`/`%` are fine in interactive one-liners but avoid them in committed `.ps1` files — use full cmdlet names).
- Scripts use `[CmdletBinding()]` and explicit `param()` blocks. Follow this pattern for any new functions.
- Use `Write-Host` (not `Write-Output`) for all user-facing terminal feedback, with `-ForegroundColor` for visual hierarchy.
- Before writing new utility logic, check whether a function already exists in `Init\` or `Scripts\`.

## Directory Layout

| Path | Purpose |
|------|---------|
| `_profile.ps1` | Entry point. Sets `$env:PSModulePath`, `$env:Path`, `$env:TEMP`/`TMP`, then dot-sources everything in `Init\`. |
| `Init\*.ps1` | Auto-loaded at boot via a `Get-ChildItem` loop. Each file defines exactly one function. Adding a new `.ps1` here is sufficient — no registration needed. |
| `Scripts\*.ps1` | Script files on `$env:Path`. Invokable directly from any terminal. Must be self-contained (no reliance on Init functions). |
| `Modules\` | Position-0 in `$env:PSModulePath`. Drop any module folder here; PowerShell finds it automatically. |

## Core Aliases & Functions

| Alias / Command | Source File | Purpose |
|-----------------|-------------|---------|
| `go` | `Init\Get-Go.ps1` | Navigate bookmarks, repos, and web URLs. Runs automatically on boot. |
| `vsp` | `Init\Set-Project.ps1` | Discover `.sln`/`.slnx` files, walk up directories with ↑, open in VS. |
| `vst` | `Init\Enable-VS.ps1` | Mount VS Developer Shell via `vswhere.exe` without resetting `$PWD`. |
| `Clean-Build` | `Scripts\Clean-Build.ps1` | Safely delete `bin`/`obj`/`.vs` only under verified project footprints. Supports `-Deep` for NuGet flush. |
| `Get-Status` | `Init\Get-Status.ps1` | Full dev environment diagnostics: Dev Drive trust state, cache sizes, env vars. |

## Dev Drive Assumptions

- `D:\` is a **ReFS Dev Drive** in async filter mode. Paths under `D:\` are always trusted/fast.
- `$env:TEMP` / `$env:TMP` are redirected to `D:\MSBuild` at profile load.
- `$env:NUGET_PACKAGES` points to `D:\.nuget\packages` (User env var, set once).
- `$env:MSBUILDCACHE_PATH` → `D:\MSBuild\Caches`, `$env:ROSLYN_COMPILER_CACHE` → `D:\MSBuild\RoslynCache`.
- If the drive falls out of trusted mode, the fix is `fsutil devdrv trust D:` (Admin CMD) — see [README.md](../README.md#1-dev-drive-falls-out-of-trusted-mode-slow-synchronous-scanning-returns).

## Common Tasks

**Add a new navigation bookmark to `go`:**  
Edit the `$StaticBookmarks` or `$PathMappings` ordered hashtable in `Init\Get-Go.ps1`.

**Add a new shell utility:**  
Create `Init\<Verb-Noun>.ps1` with a single `function <Verb-Noun> { ... }` block. It will be auto-loaded. Add an alias in `_profile.ps1` if needed.

**Add a globally runnable script:**  
Drop a `.ps1` file in `Scripts\`. It must not depend on Init-loaded functions.

**Validate the profile loads cleanly:**  
```powershell
pwsh -NoProfile -Command '. "D:\PowerShell\_profile.ps1"'
```

**Check Dev Drive trust and cache state:**  
```powershell
Get-Status
```
