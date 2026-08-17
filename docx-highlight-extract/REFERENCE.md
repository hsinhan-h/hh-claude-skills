# Reference: colors, structure, and edge cases

## Color name mapping

Word's highlighter tool only supports a fixed set of names. Map whatever the
user says (Chinese or English) to one of these before calling the script:

| User says (examples) | `w:highlight` value |
|---|---|
| 黃色 / yellow | `yellow` |
| 綠色 / green | `green` |
| 青色 / 藍綠 / cyan | `cyan` |
| 洋紅 / 桃紅 / magenta | `magenta` |
| 藍色 / blue | `blue` |
| 紅色 / red | `red` |
| 暗黃 / darkYellow | `darkYellow` |
| 暗綠 / darkGreen | `darkGreen` |
| 暗青 / darkCyan | `darkCyan` |
| 暗洋紅 / darkMagenta | `darkMagenta` |
| 暗紅 / darkRed | `darkRed` |
| 深藍 / darkBlue | `darkBlue` |
| 深灰 / darkGray | `darkGray` |
| 淺灰 / lightGray | `lightGray` |
| 黑色 / black | `black` |
| 白色 / white | `white` |

If the user instead describes a *background/cell fill color* (not the
highlighter pen tool), or the highlighter pass finds zero matches, pass a
6-digit hex code instead (e.g. `FFFF00`) — the script auto-detects hex input
and matches `w:shd fill="..."` instead of `w:highlight`.

## Why a bundled script instead of ad hoc regex

`document.xml` in a real-world spec `.docx` is routinely tens of MB. A naive
`<w:t[^>]*>` pattern also matches unrelated tags like `<w:tcPr>`, `<w:tcW>`,
`<w:tcBorders>` because they start with `w:t` too — silently corrupting
extracted text with raw XML. The bundled script requires a proper boundary
(`>` or whitespace) after `w:t`, and has been verified against a real
multi-table spec document. Always use the script rather than regenerating
this regex from scratch.

## Structure the script returns

Each JSON entry is one of:

```json
{ "type": "table-row", "cells": ["...", "..."], "header": ["...", "..."], "context": ["preceding heading text", "..."] }
```
```json
{ "type": "paragraph", "text": "..." }
```

- `header` is the first row of the enclosing table — use it as column labels
  when rendering the row as a Markdown table.
- `context` is the last few non-empty paragraphs immediately before the
  table — often a section heading or a lead-in sentence. Use it to decide
  which `##` section a table belongs under, and to write a section title.
- Rows/paragraphs are deduplicated: if a row has multiple highlighted runs
  across different cells, it appears once.

## Common edge cases

- **Merged cells**: `header` and `cells` arrays can have different lengths
  when a row spans merged columns (`w:gridSpan`). Render what's there; don't
  try to force equal column counts.
- **List paragraphs inside one cell**: a cell can contain several `<w:p>`
  numbered-list items. The script joins them with `\n` inside that cell's
  string — render as a numbered/bulleted sub-list in the Markdown output,
  not as one run-on sentence.
- **No matches found**: confirm the color mapping, then check whether the
  document uses cell shading instead of the highlighter tool (retry with a
  hex color per above). If still zero, tell the user directly instead of
  guessing.
- **Very large documents**: extraction is `indexOf`-based, not a full DOM
  parse, so it stays fast even on 20MB+ `document.xml`. No need to chunk it.
