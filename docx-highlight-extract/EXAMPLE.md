# Worked example (generic domain)

Spec document: `SPEC-042_Checkout_Flow_V3.2.docx`, version `V3.2`, color `黃色` (yellow).

Extracted JSON (abridged):

```json
[
  {
    "type": "table-row",
    "cells": ["2026/01/10", "Jane Doe", "V3.2", "新增「宅配地址」欄位"],
    "header": ["日期", "作者", "版本", "摘要"],
    "context": ["變更記錄"]
  },
  {
    "type": "table-row",
    "cells": ["", "宅配地址", "文字輸入框", "條件顯示", "顯示邏輯：當[配送方式]=宅配時顯示"],
    "header": ["#", "欄位名稱", "欄位型態", "資料來源", "說明"],
    "context": ["結帳頁", "欄位說明"]
  }
]
```

Resulting Markdown (`SPEC-042_Checkout_Flow_V3.2_黃色標註規格.md`):

```md
# SPEC-042_Checkout_Flow V3.2 黃色標註規格

> 來源文件：`SPEC-042_Checkout_Flow_V3.2.docx`
> 本文件僅整理文件中以「黃色螢光標註」(w:highlight=yellow) 標示的內容。

## 1. 版本紀錄

| 日期 | 作者 | 版本 | 摘要 |
|---|---|---|---|
| 2026/01/10 | Jane Doe | V3.2 | 新增「宅配地址」欄位 |

## 2. 結帳頁 — 欄位說明

| # | 欄位名稱 | 欄位型態 | 資料來源 | 說明 |
|---|---|---|---|---|
| — | 宅配地址 | 文字輸入框 | 條件顯示 | 顯示邏輯：當[配送方式]=宅配時顯示 |
```

Notes on the transformation:

- The `context` array (`["變更記錄"]`, `["結帳頁", "欄位說明"]`) became the
  `##` section titles — pick the most specific one, or combine them
  (`結帳頁 — 欄位說明`) when more than one is informative.
- `header` became the Markdown table's column row; `cells` became the data
  row directly beneath it.
- Entries with `"type": "paragraph"` (not shown here) become a bullet or a
  short prose block under their own `##` section instead of a table.
