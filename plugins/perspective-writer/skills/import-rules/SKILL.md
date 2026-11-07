---
name: import-rules
description: >
  Import a writing-rules file that another installed plugin publishes for perspective-writer into
  this workspace as a local copy that records its source plugin, version, path and hash. Trigger when
  the user says "匯入某 plugin 的規則", "把國科會計畫書的規則匯入", "import the rules from <plugin>",
  "freeze these plugin rules", or wants an editable local copy of a plugin's genre or subject rules.
  To use a plugin's rules without copying them (the default), a one-line include is enough — this
  skill says so when that fits better. Also trigger from /perspective-writer:import-rules directly.
argument-hint: plugin:<name>[@<marketplace>]/<path> (--genre <slug> | --subject <slug> [--genre <slug>])
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/plugin-rules.sh *), Read, AskUserQuestion, TaskCreate, TaskUpdate, TaskList
---

# Import Rules

Copy a rule file that another installed plugin publishes into this workspace's rules
namespace. The copy's first line records where it came from:

```
<!-- pw:imported plugin:<name>@<marketplace> version:<version> path:<path> sha256:<hex> date:<YYYY-MM-DD> -->
```

From then on, every resolve compares the source's current hash with the one in the
header and discloses `import-stale` when they differ. The copy is never updated
automatically. The storage layout, the plugin-side directory convention and the
import operation are defined in [`references/rules-resolution.md`](../../references/rules-resolution.md)
(*Storage layout*, *Named resolution contract*).

## Why This Exists

There are two ways to use a plugin's rules. An **include** line keeps one copy, in the
plugin, and picks up plugin updates. An **import** freezes a version (for example the
rules a submitted application was written under) or lets the workspace edit its own
copy. Import writes a file, and the target may already hold the workspace's own
rules, so this skill never replaces an existing file without the user's explicit
consent.

All access to the other plugin goes through `scripts/plugin-rules.sh`. Do not locate
the plugin's files or read its installed directory yourself.

## Step 0: Bootstrap Stage Task List（強制）

**在動任何事之前**先用 `TaskCreate` 建 stage-level todo list：

```
TaskCreate(name="step1_parse_request",   description="Step 1: 從使用者的話抽出 plugin 參照（plugin:<name>[@<marketplace>]/<path>）與目標（--genre／--subject）；沒給路徑時用 plugin 端目錄慣例，並說出用了哪個路徑")
TaskCreate(name="step2_include_or_import", description="Step 2: 使用者只是要套用規則、沒說要凍結或本地修改時，說明一行 include 即可並問要哪一種；明說匯入就直接匯入")
TaskCreate(name="step3_run_import",      description="Step 3: 執行 plugin-rules.sh import，依結束碼處理（0 回報路徑／2 轉述原因／3 停下回報紀錄問題／4 讀既有檔給使用者看，明確同意才加 --force）")
TaskCreate(name="step4_report",          description="Step 4: 回報寫入路徑、檔頭的來源版本，以及之後來源變動時會出現 import-stale")
```

完成每一步立即 `TaskUpdate → completed`。**靜默完成 = 違規**。

**為什麼強制**：Step 3 的結束碼 4 代表目標檔已存在，裡面可能是工作區自己累積的規則；漏了「先讓使用者看、明確同意才覆寫」這一步，就會把它換掉。

## Step 1: Parse the Request

| Part | Form | Example |
| ---- | ---- | ------- |
| plugin reference | `plugin:<name>@<marketplace>/<path>`; `@<marketplace>` may be omitted when only one installed plugin has that name | `plugin:grant-rules@example-plugins/perspective-writer/genres/grant-proposal.md` |
| genre target | `--genre <slug>` | `--genre grant-proposal` |
| subject target | `--subject <slug>`, optionally with `--genre <slug>` for that subject's facet | `--subject alice --genre email` |

Slugs are kebab-case: lowercase letters, digits and hyphens, starting with a letter or
digit.

When the user names a plugin and a genre but no path, use the plugin-side convention
from *Storage layout*: `perspective-writer/genres/<genre-slug>.md`, or
`perspective-writer/subjects/<subject-slug>/core.md` for a subject. Say which path you
used.

## Step 2: Include or Import

| The user wants | Use |
| -------------- | --- |
| the plugin's rules applied, kept current with the plugin | include: one line `<!-- pw:include plugin:<name>@<marketplace>/<path> -->` in the workspace's genre or subject file |
| a frozen version, or a copy to edit locally | import (this skill) |

If the user explicitly asked to import, import. If they only asked to "use" a plugin's
rules, explain the two options in one or two sentences and ask which they want.

## Step 3: Run the Import

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/plugin-rules.sh import plugin:<name>[@<marketplace>]/<path> --genre <slug>
${CLAUDE_PLUGIN_ROOT}/scripts/plugin-rules.sh import plugin:<name>[@<marketplace>]/<path> --subject <slug> [--genre <slug>]
```

The workspace defaults to the git toplevel of the current directory. Pass
`--workspace <dir>` only when the user names a different workspace.

| Exit code | Meaning | What you do |
| --------- | ------- | ----------- |
| 0 | written | go to Step 4 |
| 2 | bad arguments, the plugin or file cannot be found, the name matches several plugins, or the path is unsafe | relay the script's message as it is; if it lists several plugins, ask which one; if the conventional path was missing, ask the user for the path. Do not guess further paths |
| 3 | Claude Code's installed-plugin record cannot be read in the shape the script expects | stop and report the message; nothing was written |
| 4 | the target file already exists | Read it, show the user its first lines and whether its first line is an earlier `pw:imported` header, and ask whether to replace it. Re-run with `--force` only after an explicit yes |

## Step 4: Report

Tell the user:

- the path written (the script prints it);
- the source plugin, version and path from the header;
- that a later change to the source will be disclosed as `import-stale` when the rules
  are resolved, and that importing again with `--force` replaces the copy, including any
  local edits.
