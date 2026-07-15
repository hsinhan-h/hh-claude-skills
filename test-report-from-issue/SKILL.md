---
name: test-report-from-issue
description: Generates a Word (.docx) test report from a GitHub issue's verification checklist — a summary table plus a per-item detail section with blank space to paste results. Use when the user asks to create a test report / QA report / 測試報告 / 驗證報告 for a specific GitHub issue, or wants to turn an issue's checklist ("Test Plan", "Checklist", "驗證項目", "測試項目", or a raw "- [ ]" list) into a fillable Word document.
---

# Test Report from GitHub Issue

## Ask first if not already provided

1. Tester name
2. Which GitHub issue (number or URL)

If either is missing, ask the user — do not assume or default.

## Output language

The report's language must match the language the user is writing in (e.g. reply
in Traditional Chinese if the user is chatting in Traditional Chinese, English if
they're chatting in English). Do not hardcode a language — pass localized label
strings to the script (see step 4).

## Workflow

1. **Read the issue**: `gh issue view <issue_number> --json title,body,comments,url`
   If the target repo isn't obvious, check `git remote -v` first, or ask the user
   for `owner/repo`.

2. **Find the verification/test checklist** (a judgment task — read and decide
   yourself, don't hardcode keyword rules)
   - Look through the body and all comments for a checklist (`- [ ] ...` items),
     commonly under a heading like "Test Plan", "Checklist", "驗證項目", or
     "測試項目"
   - If there are multiple checklists, or it's unclear which one is the final
     version (e.g. a later comment revised the list), list the options for the
     user to pick — don't decide on your own
   - If no checklist exists at all, ask the user to provide the test items directly

3. **Confirm you have everything**: issue title, tester name, date (default
   today, format `YYYY/MM/DD`), the list of items, and the target language.

4. **Generate the document** (a deterministic step — call the script, don't
   hand-write the XML, and don't fall back to an HTML-disguised-as-.doc trick —
   that approach was tested and its tables overflow the page margins unreliably)

   Write the items to a temp JSON file first (avoids command-line escaping
   issues with non-ASCII/special characters), then run:

   ```powershell
   pwsh scripts/New-TestReport.ps1 `
     -Title "<issue title>" `
     -IssueNumber "<issue number>" `
     -Tester "<tester name>" `
     -Date "2026/07/15" `
     -ItemsJson "<path to temp JSON file, string array>" `
     -OutputDir "$HOME/Desktop" `
     -ReportLabel "<localized 'TestReport' label, used in the filename>" `
     -DateLabel "<localized 'Date: ' label>" `
     -TesterLabel "<localized 'Tester: ' label>" `
     -SummaryHeading "<localized '1. Test Result Summary' heading>" `
     -DetailHeading "<localized '2. Test Item Details' heading>" `
     -ColNoHeader "<localized 'No.' column header>" `
     -ColItemHeader "<localized 'Test Item' column header>" `
     -ColResultHeader "<localized 'Result (Pass/Failed)' column header>" `
     -ResultLabel "<localized 'Result: ' label>"
   ```

   All the `-...Label` / `-...Heading` / `-Col...Header` parameters default to
   English if omitted. Override them to match the user's language — see the
   Traditional Chinese example below for the values used previously.

   The script prints the full output path as the last line of stdout.

5. **Report back**: reply with that path.

## Fixed formatting rules (script-enforced, no need to ask the user)

- Filename: `Issue{issueNumber}{ReportLabel}_{YYYYMMDD}_{tester}.docx`
- Page: A4, "Moderate" margins (top/bottom 2.54cm, left/right 1.91cm); tables use
  `table-layout:fixed` with explicit column widths so long text (e.g. a URL)
  never pushes a column past the margin
- Title is the issue title; below it, a `<DateLabel><date>` line and a
  `<TesterLabel><tester>` line
- Summary section: a 3-column table (No. / Test Item / Result (Pass/Failed)),
  header row has no fill color
- Detail section: each item listed in order, followed by a bordered blank box
  for pasting the actual result

## Example (generic, not tied to any specific project)

Issue #123 "Add user avatar upload", checklist found in a comment:

```
- [ ] Uploading an image writes the correct path to the database
- [ ] An oversized image shows an error and is not uploaded
- [ ] Deleting the avatar also removes the database record
```

English conversation → ask for tester name (e.g. "Harris") → generate
`Issue123TestReport_20260715_Harris.docx` using the script's default English labels.

Traditional Chinese conversation → same issue, ask for 測試人員姓名 (e.g. "黃信翰")
→ generate `Issue123測試報告_20260715_黃信翰.docx`, calling the script with:
`-ReportLabel "測試報告" -DateLabel "Date：" -TesterLabel "測試人員：" -SummaryHeading "一：測試結果 Summary" -DetailHeading "二：測試項目明細" -ColNoHeader "編號" -ColItemHeader "測試項目" -ColResultHeader "測試結果(Pass/Failed)" -ResultLabel "測試結果："`

## Notes

- Windows filenames are case-insensitive. If a same-named file is open in Word,
  overwriting it will fail with a lock error — tell the user to close it first
  and retry.
- To adjust the format (add/remove columns, change margins, etc.), edit the
  constants/parameters in `scripts/New-TestReport.ps1` directly.
