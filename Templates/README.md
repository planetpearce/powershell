# Templates

Reusable starter packs for new projects. Each subdirectory is a self-contained package — copy the whole folder into a new repo and customise the placeholder values.

## Available Packages

| Package | Contents | Target project type |
|---|---|---|
| `vue-starter/` | `vue-copilot-instructions.md` | Vue 3 + TypeScript + Vite |

## How to Use
```powershell
# Navigate here from anywhere
go templates

# Copy a starter pack into a new project
Copy-Item -Recurse vue-starter "D:\repos\my-new-project\.github"
```

Then open the copied files and replace all `[PLACEHOLDER]` values.

---

## Copilot Instruction File Strategy

Copilot has **no memory between sessions**. The instruction files are the memory. Each session starts blank and picks up context from whichever files apply to the open workspace or file.

### How Context Is Loaded

| File | When Copilot reads it | Scope |
|---|---|---|
| `.github/copilot-instructions.md` | Always, for any file in that repo | Repo-wide |
| `.github/instructions/*.instructions.md` | When `applyTo` glob matches the open file | File-pattern scoped |
| `SKILL.md` / `*.md` skill files | On demand — invoke via Skills panel or `@workspace` | Manual reference |

### Current Instruction Files Across All Workspaces

| File | Workspace | Purpose |
|---|---|---|
| `D:\PowerShell\.github\copilot-instructions.md` | PS profile | PowerShell conventions, Dev Drive facts, function layout |
| `BikiniGit\.github\copilot-instructions.md` | All Bikini contexts | Repo topology, architecture, build constraints |
| `BikiniGit\.github\instructions\dev-ops.instructions.md` | dev-ops workspace | PS scripting, csproj editing, publish pipeline |
| `BikiniGit\.github\instructions\corepackages.instructions.md` | Visual Studio / CorePackages | DbContexts, EF migrations, NuGet versioning |
| `BikiniGit\.github\instructions\bikiniMain.instructions.md` | Visual Studio / BikiniMain | EF Core optimisation, rendering engine, architecture rules |
| `BikiniGit\dev-ops\ManageLargeSolutionArchitecture.md` | On demand | Cross-project dependency rules, consolidation TODOs |
| `Templates\vue-starter\vue-copilot-instructions.md` | Any Vue/TS project | Vue 3 + TypeScript starter (copy and customise) |

### Keeping Files Current
When the architecture changes — new project added, pattern deprecated, build step changes — update the relevant instruction file immediately. A stale instruction file is worse than none because it actively misleads Copilot.
