# VS Code Debug Setup — Reference Templates

## tasks.json template

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "build: {ProjectName}",
            "command": "dotnet",
            "type": "process",
            "args": [
                "build",
                "${workspaceFolder}/{ProjectDir}/{ProjectName}.csproj",
                "/property:GenerateFullPaths=true",
                "/consoleloggerparameters:NoSummary"
            ],
            "problemMatcher": "$msCompile",
            "group": "build"
        },
        {
            "label": "watch: {ProjectName}",
            "command": "dotnet",
            "type": "process",
            "args": [
                "watch",
                "--project",
                "${workspaceFolder}/{ProjectDir}/{ProjectName}.csproj",
                "--non-interactive",
                "run",
                "--no-restore"
            ],
            "problemMatcher": {
                "base": "$msCompile",
                "background": {
                    "activeOnStart": true,
                    "beginsPattern": "dotnet watch|Building",
                    "endsPattern": "Now listening on:|Application started|dotnet watch .*Started"
                }
            },
            "isBackground": true,
            "presentation": {
                "reveal": "always",
                "panel": "dedicated",
                "group": "watchers"
            },
            "options": {
                "env": {
                    "ASPNETCORE_ENVIRONMENT": "Development",
                    "ASPNETCORE_URLS": "{applicationUrl}",
                    "DOTNET_WATCH_RESTART_ON_RUDE_EDIT": "1",
                    "DOTNET_WATCH_SUPPRESS_EMOJIS": "1"
                }
            }
        },
        {
            "label": "build: solution",
            "command": "dotnet",
            "type": "process",
            "args": [
                "build",
                "${workspaceFolder}/{SolutionFile}",
                "/property:GenerateFullPaths=true",
                "/consoleloggerparameters:NoSummary"
            ],
            "problemMatcher": "$msCompile",
            "group": {
                "kind": "build",
                "isDefault": true
            }
        }
    ]
}
```

## launch.json templates

### Web project — Standard (no launchUrl)

```json
{
    "name": "{ProjectName}",
    "type": "coreclr",
    "request": "launch",
    "preLaunchTask": "build: {ProjectName}",
    "program": "${workspaceFolder}/{ProjectDir}/bin/Debug/{TargetFramework}/{ProjectName}.dll",
    "args": [],
    "cwd": "${workspaceFolder}/{ProjectDir}",
    "stopAtEntry": false,
    "console": "integratedTerminal",
    "serverReadyAction": {
        "action": "openExternally",
        "uriFormat": "{httpsUrl}/",
        "pattern": "Now listening on:"
    },
    "env": {
        "ASPNETCORE_ENVIRONMENT": "Development",
        "ASPNETCORE_URLS": "{applicationUrl}"
    },
    "sourceFileMap": {
        "/Views": "${workspaceFolder}"
    }
}
```

### Web project — Standard (with launchUrl, e.g. swagger)

```json
{
    "name": "{ProjectName}",
    "type": "coreclr",
    "request": "launch",
    "preLaunchTask": "build: {ProjectName}",
    "program": "${workspaceFolder}/{ProjectDir}/bin/Debug/{TargetFramework}/{ProjectName}.dll",
    "args": [],
    "cwd": "${workspaceFolder}/{ProjectDir}",
    "stopAtEntry": false,
    "console": "integratedTerminal",
    "serverReadyAction": {
        "action": "openExternally",
        "uriFormat": "{httpsUrl}/{launchUrl}",
        "pattern": "Now listening on:"
    },
    "env": {
        "ASPNETCORE_ENVIRONMENT": "Development",
        "ASPNETCORE_URLS": "{applicationUrl}"
    },
    "sourceFileMap": {
        "/Views": "${workspaceFolder}"
    }
}
```

### Web project — Hot Reload (no launchUrl)

Uses `dotnet watch` directly; no `preLaunchTask` needed. `cwd` is workspace root.

```json
{
    "name": "{ProjectName} - Hot Reload",
    "type": "coreclr",
    "request": "launch",
    "program": "dotnet",
    "args": [
        "watch",
        "--project",
        "${workspaceFolder}/{ProjectDir}/{ProjectName}.csproj",
        "--non-interactive",
        "run",
        "--no-restore",
        "--",
        "--urls={applicationUrl}"
    ],
    "cwd": "${workspaceFolder}",
    "stopAtEntry": false,
    "console": "integratedTerminal",
    "serverReadyAction": {
        "action": "openExternally",
        "uriFormat": "{httpsUrl}/",
        "pattern": "Now listening on:"
    },
    "env": {
        "ASPNETCORE_ENVIRONMENT": "Development",
        "ASPNETCORE_URLS": "{applicationUrl}"
    },
    "sourceFileMap": {
        "/Views": "${workspaceFolder}"
    }
}
```

### Web project — Hot Reload (with launchUrl, e.g. swagger)

```json
{
    "name": "{ProjectName} - Hot Reload",
    "type": "coreclr",
    "request": "launch",
    "program": "dotnet",
    "args": [
        "watch",
        "--project",
        "${workspaceFolder}/{ProjectDir}/{ProjectName}.csproj",
        "--non-interactive",
        "run",
        "--no-restore",
        "--",
        "--urls={applicationUrl}"
    ],
    "cwd": "${workspaceFolder}",
    "stopAtEntry": false,
    "console": "integratedTerminal",
    "serverReadyAction": {
        "action": "openExternally",
        "uriFormat": "{httpsUrl}/{launchUrl}",
        "pattern": "Now listening on:"
    },
    "env": {
        "ASPNETCORE_ENVIRONMENT": "Development",
        "ASPNETCORE_URLS": "{applicationUrl}"
    },
    "sourceFileMap": {
        "/Views": "${workspaceFolder}"
    }
}
```

### Test project

```json
{
    "name": "測試: {ProjectName}",
    "type": "coreclr",
    "request": "launch",
    "preLaunchTask": "build: solution",
    "program": "dotnet",
    "args": [
        "test",
        "${workspaceFolder}/{ProjectDir}/{ProjectName}.csproj",
        "--logger",
        "console;verbosity=detailed"
    ],
    "cwd": "${workspaceFolder}",
    "stopAtEntry": false,
    "console": "integratedTerminal"
}
```

### Attach to process (always append last)

```json
{
    "name": "附加至程序 (Attach)",
    "type": "coreclr",
    "request": "attach"
}
```

### Compounds (add when ≥ 2 web projects)

```json
{
    "name": "同時啟動所有 Web 專案",
    "configurations": ["{WebProject1}", "{WebProject2}"],
    "stopAll": true
},
{
    "name": "同時啟動所有 Web 專案 (Hot Reload)",
    "configurations": ["{WebProject1} - Hot Reload", "{WebProject2} - Hot Reload"],
    "stopAll": true
}
```

## Variable reference

| Variable | Description | Example |
| --- | --- | --- |
| `{ProjectName}` | `.csproj` filename without extension | `MyApp.Api` |
| `{ProjectDir}` | Project folder path relative to workspace root | `src/MyApp.Api` |
| `{TargetFramework}` | Value from `<TargetFramework>` | `net9.0` |
| `{applicationUrl}` | Full URL string from launchSettings.json | `https://localhost:5001;http://localhost:5000` |
| `{httpsUrl}` | HTTPS-only URL extracted from `applicationUrl` | `https://localhost:5001` |
| `{launchUrl}` | `launchUrl` from launchSettings.json | `swagger` |
| `{SolutionFile}` | `.sln` filename | `MyApp.sln` |
