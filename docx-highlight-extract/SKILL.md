---
name: docx-highlight-extract
description: Extracts color-highlighted (螢光標註) content from a Word .docx spec document — typically the marks used to flag one version's changes in a change-controlled spec — and writes it out as a structured Markdown file next to the source document. Use when the user wants to pull out highlighted/marked text from a Word spec (規格書/SA文件), extract a specific version's colored annotations, or convert docx highlight marks into a markdown summary.
---

# Docx Highlight Extract

Pull every paragraph/table-row marked with a given highlight color out of a
`.docx` spec document, preserving enough table/section context to render as
a real Markdown document — not a flat list of disconnected sentences.

## Step 1: Ask what to extract

If the user hasn't already given all three, ask:

1. **規格書檔名** — which `.docx` file (filename or path)?
2. **版本號** — which version does this extraction correspond to (e.g. `V3.2`)? Used for labeling and the output filename.
3. **螢光標註顏色** — which highlight color marks this version's changes (e.g. 黃色/yellow)?

## Step 2: Locate the file and unzip it

`.docx` is a zip container. Find the file (Glob for `*<name>*.docx` if the
exact path isn't given), then extract `word/document.xml` to a scratch
directory:

```bash
mkdir -p <scratch>/docx_extract
unzip -o -q "<path-to-docx>" -d <scratch>/docx_extract
```

If `unzip` isn't available, use PowerShell's `Expand-Archive` instead (it
works regardless of the `.docx` extension — it reads zip content, not the
name). Large spec docs commonly have a `document.xml` in the tens of MB —
that's normal, the bundled script handles it without a full DOM parse.

## Step 3: Run the extraction script

Map the user's color to a `w:highlight` value first — see the table in
[REFERENCE.md](REFERENCE.md). Then:

```bash
node scripts/extract-highlights.js <scratch>/docx_extract/word/document.xml <color> <scratch>/highlights.json
```

If it reports 0 matches, don't guess — re-check the color mapping with the
user, or retry with a hex color to match cell shading instead of the
highlighter tool (see REFERENCE.md).

## Step 4: Turn the JSON into Markdown

Read the JSON and build the `.md` file:

- Group entries by their `context` (the nearby heading text) into `##`
  sections, in document order.
- Render `type: table-row` entries as a Markdown table using `header` as
  the column row and `cells` as the data row. Cells with `\n` inside are a
  numbered/bulleted list within that cell — keep the line breaks, don't
  collapse them into one sentence.
- Render `type: paragraph` entries as a bullet or short prose block.
- Title the document with the spec name + version + color, and open with a
  one-line note stating it's a highlight-only extract, not the full spec.

See [EXAMPLE.md](EXAMPLE.md) for a complete worked example on a generic
domain — never carry real project/spec content into this skill itself.

## Step 5: Save and report

Save the `.md` file **in the same folder as the source `.docx`**, named
like `<規格書檔名>_<版本號>_<顏色>標註規格.md`. Report back a short summary
of the sections produced — don't dump the whole file into chat unless asked.

## Notes

- Match the conversation's language for the output document (default:
  Traditional Chinese, matching typical SA/spec documents).
- This skill extracts marked content only — it is not a full document
  summary. Say so explicitly if large parts of the doc have no highlight at
  all.
