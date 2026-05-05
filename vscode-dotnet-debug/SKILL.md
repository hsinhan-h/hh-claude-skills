---
name: vscode-debug-setup
description: Automatically generate .vscode/launch.json and .vscode/tasks.json debug configurations for .NET projects, with browser auto-open, hot reload (dotnet watch) support, and multi-project compound launch support. Use when user asks to create VS Code debug files, set up debugging, configure launch.json or tasks.json for a .NET project, or mentions "debug 設定"、"除錯設定"、"launch.json"、"建debug檔"、"hot reload"、"dotnet watch"。
---

# VS Code Debug Setup

## Workflow

### Step 1 — Scan projects

```
Glob: **/*.csproj (exclude bin/ and obj/ directories)
```

Read each `.csproj` and classify:
- **Web project**: `Sdk` attribute is `Microsoft.NET.Sdk.Web`
- **Test project**: `PackageReference` contains `xunit`, `MSTest`, or `NUnit` (case-insensitive)
- **Class Library**: everything else — skip, no launch config needed

Also collect per project:
- `<TargetFramework>` value (e.g. `net9.0`)
- Project directory (path relative to workspace root)
- Project name (`.csproj` filename without extension)

### Step 2 — Read port settings

For each **web project**, read `{ProjectDir}/Properties/launchSettings.json`:

1. Find the first non-IIS-Express profile (`commandName` is not `"IISExpress"`)
2. Take `applicationUrl` — full value (e.g. `https://localhost:5001;http://localhost:5000`)
3. Also extract `{httpsUrl}` — the https-only portion (e.g. `https://localhost:5001`)
4. If `launchUrl` is present (e.g. `swagger`), record it for use in `uriFormat`

### Step 3 — Generate tasks.json

For each **web + test project**, one `"build: {ProjectName}"` task.
Add a `"build: solution"` task (`isDefault: true`) that builds the whole `.sln` (Glob `*.sln` to get the path).
For each **web project**, also add a `"watch: {ProjectName}"` background task using `dotnet watch` for hot reload.

See [REFERENCE.md § tasks.json](REFERENCE.md#tasksjson-template).

### Step 4 — Generate launch.json

For each **web project**, generate **two** launch configurations in sequence:
1. **Standard launch**: `type: coreclr`, `preLaunchTask: "build: {ProjectName}"`, full `.dll` path as `program`, `cwd` set to project dir, `console: "integratedTerminal"`, `sourceFileMap`, and `serverReadyAction`; use `uriFormat: "{httpsUrl}/{launchUrl}"` when `launchUrl` is present, otherwise `"{httpsUrl}/"`
2. **Hot Reload launch**: `program: "dotnet"`, `args: ["watch", "--project", ..., "--non-interactive", "run", "--no-restore", "--", "--urls={applicationUrl}"]`, no `preLaunchTask`, `cwd` set to workspace root, `console: "integratedTerminal"`, `sourceFileMap`, and `serverReadyAction`

For each **test project**: one launch config with `program: "dotnet"`, `args: ["test", ...]`, `console: "integratedTerminal"`.
Always append an "Attach to Process" config at the end.

**≥ 2 web projects**: add two `compounds` entries:
1. **Standard compound** — launches all web projects using their standard configs
2. **Hot Reload compound** — launches all web projects using their Hot Reload configs

See [REFERENCE.md § launch.json](REFERENCE.md#launchjson-templates).

### Step 5 — Write files

1. `mkdir -p .vscode` (if not exists)
2. Write `.vscode/tasks.json`
3. Write `.vscode/launch.json`
4. Report each web project name, its URL, and confirm that standard + hot reload configs were generated
