---
name: gen-startup-bat
description: Analyze a project's frontend/backend startup methods and generate a Windows .bat script that users can double-click to launch both services and open a browser automatically. Use when user wants to create a startup script, generate a .bat file to start the project, or mentions "啟動腳本"、"start script"、"bat檔"、"一鍵啟動"、"雙擊啟動"、"startup bat"、"gen bat"、"產生bat"。
---

# Gen Startup BAT

## Workflow

### Step 1 — Scan project structure

Read in order of preference:
1. `CLAUDE.md` — look for dev command blocks and port info
2. frontend package manifests, checking common locations first: `client/`, `frontend/`, `web/`, `app/`, then repo root `package.json`; for monorepos also inspect `pnpm-workspace.yaml`, `package.json` `workspaces`, `turbo.json`, and `nx.json`
3. `*.sln` → referenced `*.csproj`; if no `.sln` is useful, search for `*.csproj` and prefer web/API projects with `Properties/launchSettings.json`
4. `README.md` — fallback if no structured config found

Identify:
- **Frontend dir** + **dev command** (e.g. `npm run dev`, without `cd`)
- **Backend dir** + **run command**: locate the `.csproj` file name → default to `dotnet run --project .\<name>.csproj`
- **Backend URL** from `launchSettings.json` → select a `commandName: "Project"` profile when available → read `applicationUrl`; preserve the full URL list and prefer HTTPS only when choosing a browser/API URL
- **Frontend dev server URL** from `vite.config.*` / `quasar.config.*` / framework config `server.port`; if not found, infer common defaults from scripts/frameworks

### Frontend detection details

- Prefer a package manifest that contains a runnable `dev`, `start`, or framework-specific dev script over one that only contains build/test scripts.
- In monorepos, inspect workspace packages and choose the app-like package (`vite`, `quasar`, `next`, `nuxt`, `react-scripts`, `astro`, etc.) rather than shared libraries.
- Determine the package manager from lockfiles in the frontend dir first, then parent/workspace root:
  - `pnpm-lock.yaml` → `pnpm`
  - `yarn.lock` → `yarn`
  - `bun.lock` or `bun.lockb` → `bun`
  - `package-lock.json` → `npm`
- Build the dev command from the detected package manager:
  - npm: `npm run dev` or `npm start`
  - pnpm: `pnpm dev` or `pnpm start`
  - yarn: `yarn dev` or `yarn start`
  - bun: `bun run dev` or `bun start`

### ASP.NET detection details

- Prefer `.csproj` files referenced by the `.sln`; otherwise search recursively.
- Prefer projects with `Microsoft.NET.Sdk.Web`, `launchSettings.json`, names containing `Api`, `Web`, `Server`, or `Backend`, or references to ASP.NET Core packages.
- When reading `Properties/launchSettings.json`, ignore `IIS Express` profiles unless no `Project` profile exists.
- If `applicationUrl` contains multiple URLs separated by `;`, keep them all. Use the first HTTPS URL as the preferred backend URL; otherwise use the first HTTP URL.
- Use `dotnet run --project .\<name>.csproj` by default from the backend project directory. Offer `dotnet watch --project .\<name>.csproj` only as an alternative, not the default.

### Step 2 — Ask user to confirm

Present findings and ask (one message, all at once):
1. Frontend command correct? (show detected, allow override)
2. Backend command correct? (show detected, allow override; offer `dotnet watch --project .\<name>.csproj` as alternative)
3. Browser URL to open? (default: detected frontend dev server URL)
4. Seconds to wait before opening browser? (default: `20`)
5. Output filename? (default: `<projectName>.bat` at project root, where `<projectName>` is the working directory folder name)

### Step 3 — Generate .bat file

Use the template in [REFERENCE.md](REFERENCE.md).

Fill in variables:
- `{backendLabel}` — `{projectName} - API` (derive `{projectName}` from working directory folder name)
- `{frontendLabel}` — `{projectName} - Client`
- `{backendDir}` — absolute path to backend project folder
- `{backendCommand}` — `dotnet run --project .\<name>.csproj` (default) or `dotnet watch --project .\<name>.csproj`
- `{frontendDir}` — absolute path to frontend folder
- `{frontendCommand}` — dev command without `cd`
- `{browserDelay}` — seconds to wait before opening browser (default: `20`)
- `{browserUrl}` — confirmed URL

Escape generated `.bat` values carefully:
- Quote paths with doubled quotes inside the `cmd /k` string: `cd /d ""C:\Path With Spaces""`
- Keep commands as command text, not quoted paths, unless the command itself requires quotes
- Preserve user-supplied command overrides exactly after confirmation

Write the file to the specified output path.

### Step 4 — Report

Tell the user:
- Path of the generated `.bat` file
- What each terminal window will run
- How to stop services (close the individual terminal windows)
