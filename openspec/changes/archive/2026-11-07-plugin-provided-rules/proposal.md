## Why

perspective-writer 的規則解析只讀工作區的 `.claude/.perspective-writer/`，領域 plugin（例如國科會申請文件的 plugin）沒有管道把它的文類慣例交給 perspective-writer。現在只能抄進每個工作區、各自分岔，或靠兩個 skill 剛好一起載入；後者讓規則對照者拿不到規則，而且沒有任何訊號（#25）。

## What Changes

- 新增 `plugins/perspective-writer/scripts/plugin-rules.sh`，提供兩個子指令，是本 plugin 唯一讀取 Claude Code 已安裝 plugin 紀錄（`installed_plugins.json`）的地方：
  - `expand <file>`：把規則檔裡的 `<!-- pw:include plugin:<name>@<marketplace>/<path> -->` 換成該 plugin 目前安裝版本的檔案內容，每段標出來源；檢查匯入檔的來源是否已改變；揭露清單輸出到 stderr。
  - `import <ref> --genre <slug> | --subject <slug> [--genre <slug>]`：把 plugin 的規則複製進工作區，第一行寫入來源檔頭（plugin、版本、路徑、sha256、日期）。
- 新增 skill `import-rules`，讓使用者以自然語言觸發匯入，內部呼叫上面的腳本。
- 規則解析契約（`plugins/perspective-writer/references/rules-resolution.md`）新增：include 行與匯入檔頭的格式、plugin 端目錄慣例（`<plugin-root>/perspective-writer/genres/`、`subjects/`）、四種附加揭露（`include-unresolved`、`include-nested`、`import-stale`、`redirect-unresolved`）。三種主狀態（subject-specific／legacy／generic）維持不變；轉址那一節原本的「reported as unresolved」改寫成 `redirect-unresolved` 揭露，消除與「exactly one of three statuses」的矛盾。
- `perspective-writer` 的 Phase 0b 對解析到的每個檔案呼叫 `expand`，在呈現草稿前揭露；規則對照者拿到的是展開後的全文。
- `save-feedback` 與 `draft-learner` 的 persist 只寫工作區檔案，不寫進被 include 的 plugin 檔；目標檔含 include 行時寫在其後。
- `check-contract-consistency.sh` 新增斷言：只有 `plugin-rules.sh` 與契約提到已安裝 plugin 紀錄，skill 不自己組 plugin 路徑。
- 新增 `tests/plugin-rules.test.sh`，涵蓋 #25 驗收條件 1–4。
- README 新增「從其他 plugin 提供規則」一節與 `import-rules` skill；plugin 版本 4.11.0 → 4.12.0（新增功能，非 breaking）。

## Non-Goals (optional)

（design.md 會建立，Goals／Non-Goals 寫在那裡。）

## Capabilities

### New Capabilities

- `plugin-provided-rules`: 工作區規則檔引用（include）或匯入（import）其他 plugin 提供的規則；展開、來源標示、附加揭露與 plugin 端目錄慣例。

### Modified Capabilities

(none)

## Impact

- Affected specs: `plugin-provided-rules`（新增）
- Affected code:
  - New: plugins/perspective-writer/scripts/plugin-rules.sh, plugins/perspective-writer/skills/import-rules/SKILL.md, tests/plugin-rules.test.sh
  - Modified: plugins/perspective-writer/references/rules-resolution.md, plugins/perspective-writer/skills/perspective-writer/SKILL.md, plugins/perspective-writer/agents/rules-auditor.md, plugins/perspective-writer/skills/save-feedback/SKILL.md, plugins/perspective-writer/skills/draft-learner/SKILL.md, plugins/perspective-writer/scripts/check-contract-consistency.sh, README.md, plugins/perspective-writer/CHANGELOG.md, plugins/perspective-writer/.claude-plugin/plugin.json, .claude-plugin/marketplace.json
  - Removed: (none)
- 假設（unattended 下記錄，可推翻）：已安裝 plugin 紀錄的格式是 Claude Code 的 `version: 2`（鍵為 `<name>@<marketplace>`、值為含 `installPath` 的陣列，2026-11-07 在本機核對）；形狀不符時腳本明確失敗，不猜。
