---
name: session-handoff
description: Compact the current conversation into a handoff document for another agent to pick up, saved at the project root and copied to the clipboard. Use when the user wants to end a session and hand off context to a fresh agent/session.
argument-hint: "What will the next session be used for?"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

## Where to save

Save the document at the **project root directory** — not a temp/scratchpad directory:

- Determine the project root with `git rev-parse --show-toplevel`.
- If that fails (not a git repo), fall back to the current working directory.
- Save the file directly there — do not create a `handoff/` subfolder unless one already exists.

## Filename

Format: `handoff-YYYY-mm-dd_HHmm-<topic-slug>.md`

- `YYYY-mm-dd_HHmm` — current local date and time, 24-hour, no colons/seconds (e.g. `2026-07-02_1430`).
- `<topic-slug>` — 2-4 English kebab-case words in `<scope>-<topic>` shape, e.g. `auth-flow-refactor` (scope: auth, topic: flow-refactor) or `payment-timeout-debug` (scope: payment, topic: timeout-debug). Keep it short and specific — this is what makes the file distinguishable once several handoffs pile up in the same folder.

Example: `handoff-2026-07-02_1430-auth-flow-refactor.md`

## Content

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

## After saving

Copy the full contents of the saved file to the clipboard so the user can paste it straight into the next session:

```powershell
Get-Content -Raw <path> | Set-Clipboard
```

Confirm to the user that the file was saved (state the path) and that its contents were copied to the clipboard.
