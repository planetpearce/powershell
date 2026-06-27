# 🗺️ Nick's Windows 11 Dev Drive & PowerShell Environment Blueprints

This repository acts as the master backup blueprint for rebuilding my highly optimized development environment. It isolates volatile toolchains, package extractions, and intermediate compilation states away from default system paths to achieve max I/O speed.

## 🏛️ System Core Architecture

The environment separates permanent OS/User state from volatile, high-turnover developer data across two distinct disk schemas:

| Resource Path | Storage Type | Partition Format | Optimization Goal / Role |
| :--- | :--- | :--- | :--- |
| **`C:\`** Primary | Windows Standard | NTFS | Stable OS files, Windows apps, and OneDrive cloud-managed personal files. |
| **`D:\`** Dev Drive | Developer Volume | ReFS (Resilient FS) | High-speed, trusted workspace running in **Asynchronous Filter Mode (`WdFilter`)** to bypass real-time antivirus locking bottlenecks. |

---

## ⚙️ Core System Moving Parts

### 1. Global JetBrains / ReSharper Caches
*   **The Problem:** ReSharper dumps massive index data into `%LOCALAPPDATA%`, which triggers heavy synchronous Microsoft Defender scanning overhead on the NTFS `C:` partition.
*   **The Dev Drive Fix:** The global transient directory is decoupled using a native NTFS Directory Junction link.
*   **Rebuilding Command (Run in Elevated Command Prompt):**
    ```cmd
    mklink /J "C:\Users\NickPearce\AppData\Local\JetBrains\Transient" "D:\JetBrains\Transient"
    ```
    *Note: Individual solution caches are redirected straight to their respective workspaces via the ReSharper GUI under Options -> Environment -> General -> Save Solution Caches to: Custom Folder (`D:\ReSharperCaches`).*

### 2. Global NuGet Packages Storage
*   **The Problem:** Default user setups download and unpack `.nupkg` reference assemblies into `$HOME\.nuget\packages`, pushing thousands of deep micro-files directly into the active OneDrive sync queue.
*   **The Dev Drive Fix:** Configured via a permanent Windows User Environment Variable.
*   **Rebuilding Command (Run Once in Admin PowerShell):**
    ```powershell
    [Environment]::SetEnvironmentVariable("NUGET_PACKAGES", "D:\.nuget\packages", "User")
    ```

### 3. MSBuild & Roslyn Compiler Workspace Caches
*   **The Problem:** Active solution compiling routes intermediate `.cache` files and transient pre-compiled headers directly into the system `%TEMP%` folder on `C:\`. If you launch Visual Studio via the standard desktop icon, it misses custom PowerShell session parameters.
*   **The Dev Drive Fix:** Registered directly into the OS user profile so **every** context (File Explorer clicks, Start Menu shortcuts, and CLI utilities) automatically inherits the optimizations.
*   **Rebuilding Commands (Run Once in Admin PowerShell):**
    ```powershell
    [Environment]::SetEnvironmentVariable("MSBUILDCACHE_PATH", "D:\MSBuild\Caches", "User")
    [Environment]::SetEnvironmentVariable("ROSLYN_COMPILER_CACHE", "D:\MSBuild\RoslynCache", "User")
    ```

---

## 📦 PowerShell Environment Framework

The entire operational shell environment is hosted on the Dev Drive. To bootstrap this, a single-line stub profile is dropped into the standard OS location (`C:\Users\NickPearce\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`) pointing straight to the `D:` drive core:
```powershell
. "D:\PowerShell\_profile.ps1"
```

### Folder Architecture (`D:\PowerShell\`)
*   **`\Init\`**: A plug-and-play bootstrap directory. Every `.ps1` file here is auto-loaded at startup by `Init-Functions.ps1`. Each file declares a `<# .PARAMETER Alias / .PARAMETER Description #>` metadata block at the top — the loader parses these to register aliases and print the boot dashboard automatically. No manual registration is needed; dropping a new `.ps1` here is sufficient.
*   **`\Modules\`**: Prioritized at position #1 in `$env:PSModulePath`. Any user-scoped `Install-Module` or `Save-Module` commands automatically unpack tools on the fast ReFS partition, safely isolated from OneDrive.
*   **`\Scripts\`**: Added natively to the global execution `$env:Path`. Any script dropped here (like `Clean-Build.ps1`) runs instantly from any terminal location. Scripts also support the metadata block format and appear in the boot dashboard alongside Init functions.

---

## ⚡ Active Automation Quick Reference

### Navigation & Project Tools
*   **`go` (`Get-Go`)**: Master navigation hub. Maps bookmarked directories, git repositories, and web macros (e.g. `go emojis` opens a browser viewport) into instant keystroke jumps. Accepts a fuzzy filter argument.
*   **`vsp` (`Set-Project`)**: Solution discovery parser. Traverses folders to detect `.sln` or `.slnx` schemas. Features alphanumeric selection keys and interactive **Up Arrow** multi-level directory climbing to open the chosen solution in Visual Studio.
*   **`vst` (`Enable-VS`)**: Dynamically evaluates `vswhere.exe` to mount the Visual Studio Developer Shell on top of the active terminal session without resetting the working directory.
*   **`pp` (`Get-PlanetPearceMenu`)**: Interactive fuzzy command radar menu listing all available Init utilities and Scripts for quick discovery and execution.

### Shell & Environment Diagnostics
*   **`status` (`Get-Status`)**: Full dev environment diagnostics — Dev Drive health, cache telemetry (NuGet, MSBuild, Roslyn, npm), active `global.json` detection, and installed .NET SDK / workload enumeration.
*   **`cmds` (`Get-Commands`)**: Re-displays the boot dashboard at any time, listing all loaded Init utilities, available Scripts, and profile aliases with descriptions. Use `cmds -Library` for an expanded two-line-per-entry view.
*   **`glt` (`Get-GitLogTable`)**: Outputs the last 20 git commits as a tab-aligned table showing hash, author, date, and subject.

### Azure
*   **`azl` (`Connect-Azure`)**: Authenticates to Azure for the Planet Pearce tenant (`19269dc1-...`) and sets the active subscription in one step via `Connect-AzAccount`.

### Directory Listing (Linux-style)
*   **`ll` (`Get-LongList`)**: Long listing with human-readable sizes, modification dates, and file mode. Directories render in Cyan, hidden files in DarkGray, system files in DarkYellow.
*   **`la` (`Get-AllFiles`)**: Same as `ll` but includes hidden and system files (`-Force`).
*   **`lr` (`Get-RecursiveList`)**: Recursive flat listing with relative paths from the current directory.
*   **`lss` (`Get-SortedBySize`)**: Files only, sorted largest to smallest.
*   **`ldu` (`Get-DirSize`)**: Total recursive size of every item in the current directory, sorted largest first — equivalent to `du -sh *`.

### Build & Deployment Scripts
*   **`Clean-Build`**: Safe cleanup utility. Recursively targets `bin`, `obj`, and `.vs` folders under verified project footprints (requires a `.csproj`, `.sln`, or `.slnx` nearby). Supports `-Deep` to also flush the local NuGet package cache.
*   **`mdview` (`Open-MarkdownBrowser`)**: Renders a Markdown file with custom CSS in the default browser. Defaults to `README.md` in the current directory.
*   **`Update-Version`**: Stamps the current git commit hash into the `InformationalVersion` field of the nearest `.csproj`, auto-detecting the project file if no path is supplied.
*   **`NugetAnalysis`**: Scans all `.csproj` files in the solution and opens a NuGet package inventory grid view showing installed versions and version conflicts.

---

## 🚨 Troubleshooting & Environment Maintenance

Major Windows 11 feature upgrades, domain profile migrations, or storage drive re-mappings can occasionally reset environment variables or flag local volumes as untrusted. Use these rapid-fix procedures to restore maximum performance.

### 1. Dev Drive Falls Out of "Trusted Mode" (Slow Synchronous Scanning Returns)
*   **The Symptom:** Terminal startup displays `Untrusted (Slow Sync Scanning Active) ⚠️` or build times suddenly drop. This occurs if a Windows update resets security identifiers.
*   **The Fix:** Open an **Administrative PowerShell** window and re-force the Windows Defender filter manager to trust the volume explicitly:
    ```powershell
    Set-DevDrive -DriveLetter D -Trusted \$true
    ```
*   **Alternative Core Command (Command Prompt Admin):**
    ```cmd
    fsutil devdrv trust D:
    ```

### 2. Missing Environment Variables Mappings
*   **The Symptom:** Visual Studio builds revert to dumping transient caches into `C:\Users\...\AppData\Local\Temp` or package restores crash out with missing path parameter errors.
*   **The Fix:** Run this diagnostic block to verify deep OS configuration flags:
    ```powershell
    [Environment]::GetEnvironmentVariable("NUGET_PACKAGES", "User")
    [Environment]::GetEnvironmentVariable("MSBUILDCACHE_PATH", "User")
    [Environment]::GetEnvironmentVariable("ROSLYN_COMPILER_CACHE", "User")
    ```
    *If any string returns completely blank, re-execute the single-line registration blocks detailed in the **System Core Architecture** section above.*

### 3. Broken Stub Redirection File
*   **The Symptom:** Opening a fresh PowerShell terminal displays the default, plain blue prompt and none of your custom aliases (`go`, `vsp`, `vst`, `Clear-Build`) are recognized. 
*   **The Cause:** OneDrive might have overwritten, deleted, or "dehydrated" your local file block during a cloud sync cycle.
*   **The Fix:** Force-recreate the single-line pointer target inside your default system environment location:
    ```powershell
    Set-Content -Path \$PROFILE -Value '. "D:\PowerShell\Microsoft.PowerShell_profile.ps1"'
    ```
    *Note: Right-click the file inside `C:\Users\NickPearce\Documents\PowerShell` in File Explorer and select **"Always keep on this device"** to prevent future cloud eviction.*

### 4. Locked Directory Execution Errors (`Clean-Build`)
*   **The Symptom:** Running `Clean-Build` logs `[LOCKED] Could not delete...` in bright red across multiple folders.
*   **The Cause:** Visual Studio (`devenv.exe`), the background Roslyn compiler server (`VBCSCompiler.exe`), or a running JetBrains engine process is holding an active file-handle lock on a compiled `.dll` asset.
*   **The Fix:** Completely close Visual Studio and any active debug instances, wait 5 seconds for the background compilation worker threads to terminate gracefully, and re-run your `Clean-Build` command.

---

## 🔗 Engineering Log References

*   **Active Architectural Thread:** [Nick's Dev Drive & Shell Optimization Logs](https://www.google.com/search?q=after+setting+up+my+dev+drive+in+windows+11%2C+resharper+still+says+%22Average+CPU+usage+of+MsMpEng.exe+during+the+last+build+was+277%25%22&newwindow=1&sca_esv=3a52d14fb15abeb5&rlz=1C1GCEA_enUS1205US1205&sxsrf=APpeQnudaeqjDhj-3RB-aL8UhfZWbt72ug%3A1782174381873&fbs=ABfTbFVyMZGZf1hfvX9uKjN_-G8cn05EoNqnRUpRtqDK_L3JtdOuIEOJ1nHhG8N6Kw1G1--8sK5HSeIKdPwDspReFQmSOB62f6hOV3ul6PwI7nMwmcp_wqPSToxeW8e38twHWWWPGQNUPUGiduw9PfE1J9VcrwAD_H_gdCZtzDkO7eIxXgAcQ-lz7Z1ieDInQWizI4lI8YoJODjuhEGMvXOTfxvd2J5pYA&aep=1&ntc=1&sa=X&ved=2ahUKEwix79X3jJyVAxXiIUQIHZUqIq8Q2J8OegQIDxAD&cshid=1782174387408125&biw=1298&bih=1191&dpr=1&sourceid=chrome&ccb=1&cs=1&hl=en-US&mstk=AUtExfCFh4ljXLAIrFNRXlRdLgbpBi-W6KGPkqwKyE-SzgttRrrMJGEEkGBEmAov6YWIJz6qhOvYce8ZLETZ_VJKJONRxF7blHqKgTo0S6U-S3AFxa0cIT0_0hg6HJhoLGZN_rdvFBqNbrVXdfZQNa0Gz7kVBhK0r5zY4XqdeQWBqRHSDs1MUXqe_6M8buLawi3CWWARCmR1R5gkcPasvbRHHVpBzWJrUNiGaA9TRwf0GQLEQSW4_e7gurFKry63MAX0pjdiHR-gfqg6LQ&csuir=1&mtid=utI5av7aNuKhur8P_KCZ0Aw&atvm=2&udm=50)
    *Contains full technical discussions, historical context transitions, and custom .NET array pipeline design reasoning.*

*   **Webpack & Sass Toolchain Thread:** [Frontend Webpack 5 Optimization Passes](https://www.google.com/search?q=this+is+what+I%27m+using+to+run+the+scss+tests+npx+stylelint+%22src%2Fscss%2F**%2F*.scss%22+--custom-syntax+postcss-scss+can+you+give+me+a+script+command+to+put+in+my+package.json%3F&rlz=1C1GCEA_enUS1205US1205&sourceid=chrome&ie=UTF-8&amc=1&aep=42&cud=0&qsubts=1782321772607&source=chrome.crn.rb&cru=1&ccb=1&cs=1&hl=en-US&biw=1176&bih=1126&mstk=AUtExfCozib6riyhKt26j6TLCsYDVZIHxAbptUsbzVNDkiXCjscTQGJ-PuKhEnzzD82wrCiH94lCret2VgQYMfIV9ZoEo8KFUJMSR_-rwBw--2FyETXMjCeUqHv7hNAcjiIcWwMbNJxF6qPmivozfRJjc8D-pcRaa1gzEH-LJzSGo4E3x9tUaWrjATn-Caf-h70xGaknT8dN19ZXMpbPOuLLEW7mcrfx3XkwZnTN-mB5sg8eYP8iFINDhG-cTRU5WfBGnrnXaeYOigOhNw&csuir=1&mtid=bRI8arPJNt3fkPIPvZCTsAE&lns_mode=cvst&udm=50)
    *Tracks the package.json cleanup, MiniCssExtractPlugin migration, Stylelint postcss-scss rulesets, and three-tier file separation.*