# hh-claude-skills

[繁體中文](README.md) | **English**

A personal collection of [Claude Code](https://claude.com/claude-code) skills for everyday development work: commit messages, startup scripts, debug configs, flow walkthroughs, test reports, and Word spec processing.

## Skills

| Skill | What it does |
| --- | --- |
| [commit-msg](commit-msg/SKILL.md) | Generates a Conventional Commits message from staged changes, matching the language of recent commits. |
| [docx-highlight-extract](docx-highlight-extract/SKILL.md) | Extracts highlighted (color-marked) content from a Word `.docx` spec and writes it as structured Markdown next to the source file. |
| [explain-flow](explain-flow/SKILL.md) | Traces the end-to-end execution of a batch job, script, pipeline or request handler and writes a phase-by-phase walkthrough with code references and an ASCII flow diagram under `docs/`. |
| [gen-startup-bat](gen-startup-bat/SKILL.md) | Detects a project's frontend/backend start commands and generates a double-clickable Windows `.bat` that launches both and opens the browser. |
| [session-handoff](session-handoff/SKILL.md) | Compacts the current conversation into a handoff document at the project root and copies it to the clipboard, so a fresh session can continue the work. |
| [test-report-from-issue](test-report-from-issue/SKILL.md) | Turns a GitHub issue's verification checklist into a Word (`.docx`) test report with a summary table and per-item sections for pasting results. |
| [vscode-dotnet-debug](vscode-dotnet-debug/SKILL.md) | Generates `.vscode/launch.json` and `tasks.json` for .NET projects, with browser auto-open, hot reload (`dotnet watch`) and multi-project compound launch. Skill name: `vscode-debug-setup`. |

### commit-msg

Reads `git diff --staged` and writes a commit message in Conventional Commits format. It checks recent commit history to decide between Traditional Chinese and English.

- **Trigger:** "generate commit message", "幫我寫commit", "commit 怎麼寫", or a request to commit staged changes.

### docx-highlight-extract

Pulls every paragraph and table row marked with a given highlight color out of a `.docx` file, keeping the table headers and section context so the result reads as a real document rather than a list of fragments. Typically used to isolate one version's changes in a change-controlled spec.

- **Asks for:** the spec file, the version number (e.g. `V3.2`), and the highlight color.
- **Output:** a `.md` file in the same folder as the source `.docx`.
- **Requires:** Node.js (runs [scripts/extract-highlights.js](docx-highlight-extract/scripts/extract-highlights.js)).

### explain-flow

Finds the entry point of a sequential component, reads it and everything it calls in full, then documents the real control flow phase by phase with file and line citations.

- **Trigger:** "explain how this batch job works", "walk me through this", "完整流程".
- **Output:** a Markdown walkthrough saved under the project's `docs/` folder and printed in chat.

### gen-startup-bat

Scans `CLAUDE.md`, `package.json` files, `.sln`/`.csproj` and `launchSettings.json` to find how the frontend and backend start and which ports they use, confirms the details with you, then writes the `.bat` file.

- **Trigger:** "啟動腳本", "一鍵啟動", "startup bat", "產生bat".
- **Output:** `<projectName>.bat` at the project root by default.

### session-handoff

Summarises the current session into a document a new agent can pick up from. It suggests skills for the next agent to use, links to existing PRDs, issues and commits instead of copying them, and redacts secrets.

- **Argument:** what the next session will be used for.
- **Output:** `handoff-YYYY-mm-dd_HHmm-<topic>.md` at the git root, also copied to the clipboard.

### test-report-from-issue

Reads a GitHub issue with `gh`, finds its checklist (Test Plan, Checklist, 驗證項目, or a raw `- [ ]` list) and builds a fillable Word test report. Labels follow the language you're chatting in.

- **Asks for:** the tester's name and the issue number or URL.
- **Requires:** [GitHub CLI](https://cli.github.com/) (`gh`) and PowerShell (runs [scripts/New-TestReport.ps1](test-report-from-issue/scripts/New-TestReport.ps1), no other dependencies).

### vscode-dotnet-debug

Scans all `.csproj` files, classifies them as web, test or class library projects, and generates matching VS Code debug and build configurations.

- **Trigger:** "debug 設定", "launch.json", "建debug檔", "hot reload", "dotnet watch".
- **Output:** `.vscode/launch.json` and `.vscode/tasks.json`.

## Installation

Clone the repo and copy (or symlink) the skill folders you want into your Claude Code skills directory:

- **Personal (all projects):** `~/.claude/skills/`
- **Single project:** `<project>/.claude/skills/`

```bash
git clone https://github.com/hsinhan-h/hh-claude-skills.git
cp -r hh-claude-skills/commit-msg ~/.claude/skills/
```

Each folder must keep its `SKILL.md` at the top level. Claude Code picks up skills automatically; invoke one by describing the task, or directly with `/<skill-name>`.

## Folder layout

```text
<skill>/
├── SKILL.md       # Required: frontmatter (name, description) + instructions
├── REFERENCE.md   # Optional: detailed rules and templates
├── EXAMPLE.md     # Optional: sample output
└── scripts/       # Optional: helper scripts the skill runs
```
