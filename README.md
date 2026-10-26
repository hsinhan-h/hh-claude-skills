# hh-claude-skills

**繁體中文** | [English](README.en.md)

個人使用的 [Claude Code](https://claude.com/claude-code) Skill 合集，涵蓋日常開發常見工作：產生 commit 訊息、啟動腳本、除錯設定、程式流程說明、測試報告，以及 Word 規格書處理。

## Skill 一覽

| Skill | 用途 |
| --- | --- |
| [commit-msg](commit-msg/SKILL.md) | 根據 staged 變更產生 Conventional Commits 格式的 commit 訊息，語言會跟隨近期 commit 的慣例。 |
| [docx-highlight-extract](docx-highlight-extract/SKILL.md) | 擷取 Word `.docx` 規格書中的螢光標註內容，整理成結構化的 Markdown，存放在原檔旁邊。 |
| [explain-flow](explain-flow/SKILL.md) | 追蹤批次作業、腳本、pipeline 或 request handler 的完整執行流程，在 `docs/` 下產出分階段說明，附程式碼位置與 ASCII 流程圖。 |
| [gen-startup-bat](gen-startup-bat/SKILL.md) | 偵測專案前後端的啟動方式，產生可雙擊執行的 Windows `.bat`，一鍵啟動前後端並開啟瀏覽器。 |
| [session-handoff](session-handoff/SKILL.md) | 將目前對話濃縮成交接文件，存放在專案根目錄並複製到剪貼簿，讓新的 session 可以接手。 |
| [test-report-from-issue](test-report-from-issue/SKILL.md) | 將 GitHub issue 中的驗證清單轉成 Word（`.docx`）測試報告，包含總覽表與每個項目的結果貼圖區。 |
| [vscode-dotnet-debug](vscode-dotnet-debug/SKILL.md) | 為 .NET 專案產生 `.vscode/launch.json` 與 `tasks.json`，支援自動開啟瀏覽器、hot reload（`dotnet watch`）及多專案同時啟動。Skill 名稱為 `vscode-debug-setup`。 |

### commit-msg

讀取 `git diff --staged`，產生 Conventional Commits 格式的 commit 訊息，並參考近期 commit 紀錄決定使用繁體中文或英文。

- **觸發方式：**「幫我產commit message」、「幫我寫commit」、「commit 怎麼寫」，或要求 commit staged 變更。

### docx-highlight-extract

從 `.docx` 中取出所有以指定螢光顏色標註的段落與表格列，並保留表頭與章節脈絡，讓輸出讀起來是完整文件，而不是零散的句子。常用於從版本控管的規格書中，抽出某一版的變更內容。

- **會詢問：** 規格書檔名、版本號（例如 `V3.2`）、螢光標註顏色。
- **產出：** 與原 `.docx` 放在同一資料夾的 `.md` 檔。
- **需求：** Node.js（執行 [scripts/extract-highlights.js](docx-highlight-extract/scripts/extract-highlights.js)）。

### explain-flow

找出循序型元件的進入點，完整讀過它及其呼叫的所有程式碼後，依實際執行順序分階段說明控制流程，並附上檔案與行號。

- **觸發方式：**「說明這個批次怎麼運作」、「walk me through this」、「完整流程」。
- **產出：** 存放在專案 `docs/` 資料夾的 Markdown 說明文件，同時顯示在對話中。

### gen-startup-bat

掃描 `CLAUDE.md`、`package.json`、`.sln`/`.csproj` 與 `launchSettings.json`，找出前後端的啟動指令與使用的 port，跟你確認後寫出 `.bat` 檔。

- **觸發方式：**「啟動腳本」、「一鍵啟動」、「雙擊啟動」、「產生bat」。
- **產出：** 預設為專案根目錄下的 `<專案名稱>.bat`。

### session-handoff

將本次 session 整理成交接文件，讓新的 agent 可以直接接續工作。文件會建議下一個 agent 該使用的 Skill，已有的 PRD、issue、commit 只附連結不重複內容，並遮蔽機敏資訊。

- **參數：** 下一個 session 要做什麼。
- **產出：** git 根目錄下的 `handoff-YYYY-mm-dd_HHmm-<主題>.md`，內容同時複製到剪貼簿。

### test-report-from-issue

透過 `gh` 讀取 GitHub issue，找出其中的檢查清單（Test Plan、Checklist、驗證項目，或單純的 `- [ ]` 清單），產生可填寫的 Word 測試報告。報告文字會跟隨對話使用的語言。

- **會詢問：** 測試人員姓名、issue 編號或網址。
- **需求：** [GitHub CLI](https://cli.github.com/)（`gh`）與 PowerShell（執行 [scripts/New-TestReport.ps1](test-report-from-issue/scripts/New-TestReport.ps1)，無其他相依套件）。

### vscode-dotnet-debug

掃描所有 `.csproj`，分類為 Web、測試或類別庫專案，並產生對應的 VS Code 除錯與建置設定。

- **觸發方式：**「debug 設定」、「除錯設定」、「建debug檔」、「launch.json」、「hot reload」。
- **產出：** `.vscode/launch.json` 與 `.vscode/tasks.json`。

## 安裝方式

Clone 此 repo，將需要的 Skill 資料夾複製（或建立 symlink）到 Claude Code 的 skills 目錄：

- **個人（所有專案通用）：** `~/.claude/skills/`
- **單一專案：** `<專案>/.claude/skills/`

```bash
git clone https://github.com/hsinhan-h/hh-claude-skills.git
cp -r hh-claude-skills/commit-msg ~/.claude/skills/
```

每個資料夾的最上層都必須保留 `SKILL.md`。Claude Code 會自動載入 Skill，描述你要做的事即可觸發，也可以直接輸入 `/<skill-name>` 呼叫。

## 資料夾結構

```text
<skill>/
├── SKILL.md       # 必要：frontmatter（name、description）與執行步驟
├── REFERENCE.md   # 選用：詳細規則與範本
├── EXAMPLE.md     # 選用：輸出範例
└── scripts/       # 選用：Skill 執行時使用的輔助腳本
```
