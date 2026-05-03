---
name: commit-msg
description: Generate a conventional commit message from staged git changes. Use this skill whenever the user asks to generate, write, or produce a commit message — including phrases like "幫我產commit message", "generate commit message", "根據staged changes產commit message", "commit訊息", "幫我寫commit", "產生commit", "寫commit message", "commit 怎麼寫", or any request to commit staged changes. Always invoke this skill before writing commit messages yourself.
---

# Commit Message Generator

Generate a well-structured commit message based on the current staged changes.

## Step 1: Read the staged diff

```bash
git diff --staged
```

If there are no staged changes, tell the user and stop. Suggest they run `git add <files>` first.

Also check the language used in recent commits to decide whether the message should be in Traditional Chinese or English:

```bash
git log --oneline -5
```

Use Traditional Chinese if recent commits are in Chinese, otherwise use English.

## Step 2: Analyze the changes

Look at what files changed and what the diff shows. Ask yourself:
- What was the purpose of this change from a user's perspective?
- Does it add new capability, fix broken behavior, update structure, or something else?

## Step 3: Pick the commit type

Choose exactly one type based on the primary intent of the change:

| Type | When to use |
|------|-------------|
| `feat` | New feature for the user (not a build-script feature) |
| `fix` | Bug fix for the user (not a build-script fix) |
| `docs` | Documentation only — no code logic changed |
| `style` | Formatting, whitespace, semicolons — zero semantic change |
| `refactor` | Code restructured without fixing a bug or adding a feature |
| `chore` | Maintenance, dependency updates, config — no production code touched |
| `perf` | Performance improvement |
| `revert` | Reverts a previous commit |
| `test` | Adding or fixing tests — no production code change |
| `build` | Build system or external dependency changes (e.g., webpack, npm scripts) |
| `ci` | CI/CD configuration (e.g., GitHub Actions, workflows) |

When the diff spans multiple types, pick the one that best describes the primary intent.

## Step 4: Write the commit message

**Title format:**
```
type: short description (imperative mood, under 72 chars)
```

Examples:
- `feat: 新增使用者登入功能`
- `fix: 修正 MongoDB 連線逾時問題`
- `refactor: extract database connection logic into helper`

**Body (bullet points):**

List specific changes and their reasons below the title, each starting with `-`. Focus on the *why* and *what*, not just restating the file names.

```
feat: 新增跨容器通訊範例

- 新增 Node.js app 容器，透過 Docker 自訂網路連接 MongoDB
- 使用 mongoose 連線，並修正 useUnifiedTopology 設定以符合新版 API
- 在 docker-compose.yml 定義 app-network 讓容器間可互相解析主機名稱
```

## Step 5: Present and confirm

Display the commit message in a code block so the user can copy it easily:

````
```
type: title here

- detail one
- detail two
- detail three
```
````

Then ask: **"要直接用這個 commit message 提交嗎？"** (or in English if the message is in English: **"Would you like me to apply this commit message now?"**)

If the user confirms, run:

```bash
git commit -m "$(cat <<'EOF'
type: title here

- detail one
- detail two
- detail three
EOF
)"
```

If the user wants edits, apply them first before committing.
