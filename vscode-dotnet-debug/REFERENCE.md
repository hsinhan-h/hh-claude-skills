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

### Web project (no launchUrl)

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
    "serverReadyAction": {
        "action": "openExternally",
        "pattern": "\\bNow listening on:\\s+(https?://\\S+)"
    },
    "env": {
        "ASPNETCORE_ENVIRONMENT": "Development",
        "ASPNETCORE_URLS": "{applicationUrl}"
    }
}
```

### Web project (with launchUrl, e.g. swagger)

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
    "serverReadyAction": {
        "action": "openExternally",
        "uriFormat": "%s/{launchUrl}",
        "pattern": "\\bNow listening on:\\s+(https?://\\S+)"
    },
    "env": {
        "ASPNETCORE_ENVIRONMENT": "Development",
        "ASPNETCORE_URLS": "{applicationUrl}"
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

### Compound (add when ≥ 2 web projects)

```json
{
    "name": "同時啟動所有 Web 專案",
    "configurations": ["{WebProject1}", "{WebProject2}"],
    "stopAll": true
}
```

## Variable reference

| Variable | Description | Example |
|---|---|---|
| `{ProjectName}` | `.csproj` filename without extension | `MyApp.Api` |
| `{ProjectDir}` | Project folder path relative to workspace root | `src/MyApp.Api` |
| `{TargetFramework}` | Value from `<TargetFramework>` | `net9.0` |
| `{applicationUrl}` | URL from launchSettings.json | `https://localhost:5001;http://localhost:5000` |
| `{launchUrl}` | `launchUrl` from launchSettings.json | `swagger` |
| `{SolutionFile}` | `.sln` filename | `MyApp.sln` |
