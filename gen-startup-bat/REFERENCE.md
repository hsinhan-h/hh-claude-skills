# Gen Startup BAT — Reference Template

## .bat template

```bat
@echo off
start "{backendLabel}" cmd /k "cd /d ""{backendDir}"" && {backendCommand}"
start "{frontendLabel}" cmd /k "cd /d ""{frontendDir}"" && {frontendCommand}"
timeout /t {browserDelay} /nobreak > nul
start "" "{browserUrl}"
```

## Variable reference

| Variable | Description | Example |
| --- | --- | --- |
| `{backendLabel}` | Window title for backend terminal — derived from folder name: `{projectName} - API` | `my-app - API` |
| `{backendDir}` | Absolute path to backend project directory | `C:\Projects\my-app\server\my-app-api` |
| `{backendCommand}` | Backend run command (no `cd`) | `dotnet run --project .\my-app-api.csproj` |
| `{frontendLabel}` | Window title for frontend terminal — derived from folder name: `{projectName} - Client` | `my-app - Client` |
| `{frontendDir}` | Absolute path to frontend directory | `C:\Projects\my-app\client` |
| `{frontendCommand}` | Frontend dev command (no `cd`), using the detected package manager | `pnpm dev` |
| `{browserDelay}` | Seconds to wait before opening browser | `20` |
| `{browserUrl}` | URL to open in browser | `http://localhost:5173` |

## Notes on paths

- Always use absolute paths in `cd /d` — relative paths break when .bat is run from a different directory
- Quote paths that contain spaces: `cd /d "C:\My Project\client"`
- Inside the `cmd /k "..."` string, quote paths with doubled quotes: `cd /d ""C:\My Project\client""`
- Detect `.csproj` filename from the backend directory; use `dotnet run --project .\<name>.csproj`
- Offer `dotnet watch --project .\<name>.csproj` as a hot-reload alternative

## Notes on frontend detection

- Check common frontend directories first: `client`, `frontend`, `web`, `app`, then the repository root.
- For monorepos, inspect `pnpm-workspace.yaml`, root `package.json` `workspaces`, `turbo.json`, and `nx.json`; choose an app package rather than a shared library package.
- Choose the package manager from the nearest lockfile:

| Lockfile | Command style |
| --- | --- |
| `pnpm-lock.yaml` | `pnpm dev` / `pnpm start` |
| `yarn.lock` | `yarn dev` / `yarn start` |
| `bun.lock`, `bun.lockb` | `bun run dev` / `bun start` |
| `package-lock.json` or no lockfile | `npm run dev` / `npm start` |

## Notes on ASP.NET detection

- Prefer `.csproj` files referenced by the `.sln`; otherwise search recursively.
- Prefer web/API projects: `Microsoft.NET.Sdk.Web`, `Properties/launchSettings.json`, or project names containing `Api`, `Web`, `Server`, or `Backend`.
- In `launchSettings.json`, prefer profiles with `commandName: "Project"` over `IIS Express`.
- `applicationUrl` can contain multiple URLs separated by `;`. Keep all URLs for reporting; use the first HTTPS URL as the preferred backend URL, falling back to the first HTTP URL.

## Notes on delays

- Both services start simultaneously — no delay between backend and frontend
- Only one `timeout` before browser open (default 20s — covers both ASP.NET Core + Quasar/Vite cold start)
- Adjust `{browserDelay}` based on machine speed

## Multi-backend variant (optional)

If the project has multiple backend services, add more `start` lines before the `timeout`:

```bat
@echo off
start "{backendLabel1}" cmd /k "cd /d ""{backendDir1}"" && {backendCommand1}"
start "{backendLabel2}" cmd /k "cd /d ""{backendDir2}"" && {backendCommand2}"
start "{frontendLabel}" cmd /k "cd /d ""{frontendDir}"" && {frontendCommand}"
timeout /t {browserDelay} /nobreak > nul
start "" "{browserUrl}"
```
