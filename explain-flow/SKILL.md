---
name: explain-flow
description: Traces the end-to-end execution flow of a sequential/procedural component (batch job, script, pipeline, cron task, workflow, or request handler — spanning one file or several files/services) and writes it up as a structured Markdown walkthrough with phase-by-phase code references and an ASCII flow diagram, saved under the project's docs/ folder. Use when the user asks to explain or document how a batch job, script, task, or pipeline works end-to-end, wants a "完整流程" / "flow walkthrough" / "walk me through this", or needs to understand execution order across an entry point.
---

# Explain Flow

Produce a code-grounded, phase-by-phase walkthrough of how a sequential component actually
executes — not a paraphrase of file names, a trace of real control flow with citations.

## Quick start

1. Find the entry point (main class/function, script, cron handler, message consumer).
2. Read it — and everything it directly calls — **in full** before writing a single line.
   Never write from a partial read; for large files read in chunks until you've covered
   the whole thing.
3. Split the logic into phases using the taxonomy below, in true execution order.
4. Write the walkthrough with the template below.
5. Save it under the project's `docs/` folder (create the folder if missing) **and** print
   the full walkthrough as your chat response — saving the file is not a substitute for
   showing the content. Don't make the user open the file to read it.

## Phase taxonomy

| Phase | Covers | Ask yourself |
|---|---|---|
| 0. Entry / Init | What runs before real work starts: config load, connection setup, arg parsing | What has to be true/loaded before step 1 can run? |
| 1. Input Acquisition | Where source data enters: queries, file listing, queue read, API pull | Is there more than one source/condition? (tabulate if so) |
| 2. Processing | The core per-item logic, including branches and guard conditions | What decides whether an item is skipped, retried, or processed? |
| 3. Output / Side Effects | What gets written, sent, or uploaded, and in what format/contract | What downstream system consumes this, and how does it know the output is complete? |
| 4. Wrap-up | Cleanup, notifications, status/return codes, re-triggered jobs | What does success vs. failure look like to whatever calls this? |

For multi-file or cross-service flows, treat each hop as a sub-phase nested under the phase
it belongs to (e.g. "2a. OrderService.charge()") — see [REFERENCE.md](REFERENCE.md) for how
to find and bound the trace.

## Rules

- **Read before writing.** Every phase description must be backed by code you've actually
  opened — cite `File.ext:line` or `File.ext:startLine-endLine` for every method/branch you
  name. Don't infer behavior from a function name alone.
- **Tabulate parallel sources.** If a phase pulls from more than one source/condition (e.g.
  three queries feeding one list), use a table: source | method/query | condition — not prose.
- **Name mechanisms, don't fabricate values.** If a step depends on external config (env var,
  config file, secret), name the mechanism and where it's read from; don't guess the actual
  value unless you've opened the file.
- **ASCII diagram only.** Close with a plain-text box-and-arrow diagram summarizing phases and
  major branches — no Mermaid, so it renders anywhere the doc is opened.
- **Always show the content, not just the save path.** Output the full walkthrough in the
  chat response (same content as the saved file) — never respond with only a confirmation
  that a file was written.
- **Stay descriptive.** This skill documents what the flow *is*, not what's wrong with it. Skip
  bug/code-smell commentary — that's a separate review task.
- **Match the conversation's language** for the output document (if the user asked in
  Traditional Chinese, write the doc in Traditional Chinese, etc.). If the conversation
  gives no clear signal either way, **default to Traditional Chinese**.
- **Generic when teaching, specific when documenting.** When explaining this skill's own use
  (e.g. to a template or another user), use a generic example domain, never real project
  internals.

## Output template

```md
# {ComponentName} 完整流程 / Complete Flow

> Entry point: `{path/to/entry/file}`

## 0. {Entry / Init phase name}
...

## 1. {Input Acquisition phase name}
| Source | Method/Query | Condition |
|---|---|---|
...

## 2. {Processing phase name}
1. ...
2. ...

## 3. {Output phase name}
...

## 4. {Wrap-up phase name}
...

## Flow Diagram
\```
[ASCII box-and-arrow diagram]
\```

{1-2 sentence closing paragraph translating the technical steps into the operational/business purpose}
```

See [EXAMPLE.md](EXAMPLE.md) for a complete worked example on a generic domain.
