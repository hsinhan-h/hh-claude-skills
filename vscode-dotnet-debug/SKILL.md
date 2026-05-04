---
name: vscode-debug-setup
description: Automatically generate .vscode/launch.json and .vscode/tasks.json debug configurations for .NET projects, with browser auto-open and multi-project compound launch support. Use when user asks to create VS Code debug files, set up debugging, configure launch.json or tasks.json for a .NET project, or mentions "debug 設定"、"除錯設定"、"launch.json"、"建debug檔"。
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
2. Take `applicationUrl` — prefer the `https://` URL if multiple are listed
3. If `launchUrl` is present (e.g. `swagger`), record it for use in `uriFormat`

### Step 3 — Generate tasks.json

One build task per web + test project, label format: `"build: {ProjectName}"`.
Add a `"build: solution"` task (`isDefault: true`) that builds the whole `.sln` (Glob `*.sln` to get the path).

See [REFERENCE.md § tasks.json](REFERENCE.md#tasksjson-template).

### Step 4 — Generate launch.json

- **Web project**: coreclr launch with `serverReadyAction`; add `uriFormat: "%s/{launchUrl}"` when `launchUrl` is present
- **Test project**: `program: "dotnet"`, `args: ["test", ...]`, `console: "integratedTerminal"`
- Always append an "Attach to Process" config at the end
- **≥ 2 web projects**: add a `compounds` entry to launch all web projects at once

See [REFERENCE.md § launch.json](REFERENCE.md#launchjson-templates).

### Step 5 — Write files

1. `mkdir -p .vscode` (if not exists)
2. Write `.vscode/tasks.json`
3. Write `.vscode/launch.json`
4. Report each web project name and its URL
