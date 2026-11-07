## Why

#25 讓 core skill 的 Phase 0b 對 resolve 回傳的每個檔案先跑 `plugin-rules.sh expand` 再讀。`role-calibrator`、`draft-learner`、`save-feedback` 也讀規則（比對、去重、決定寫在哪），卻仍讀原始檔。工作區規則檔若主要是一行 `pw:include`，它們只看到一行註解，可能提出 plugin 規則早已涵蓋或與之矛盾的新規則（#29）。

## What Changes

- 三個 skill 比對既有規則前，對每個檔案跑 `plugin-rules.sh expand`，讀 stdout，並把附加揭露告訴使用者。寫入仍只寫工作區的原始檔、寫在 include 行之後。
- `check-contract-consistency.sh` 新增斷言：提到 resolve 或 persist 的 skill 必須提到 `plugin-rules.sh expand`，並有反例測試。

## Non-Goals

- 不改 persist 的寫入規則（#25 已定）。
- 不改 core skill 的 Phase 0b。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `plugin-provided-rules`: 讀規則來比對的 skill 都讀展開後的內容

## Impact

- Affected specs: `plugin-provided-rules`
- Affected code:
  - Modified: plugins/perspective-writer/skills/role-calibrator/SKILL.md, plugins/perspective-writer/skills/draft-learner/SKILL.md, plugins/perspective-writer/skills/save-feedback/SKILL.md, plugins/perspective-writer/scripts/check-contract-consistency.sh, tests/plugin-rules.test.sh, plugins/perspective-writer/CHANGELOG.md, plugins/perspective-writer/.claude-plugin/plugin.json, .claude-plugin/marketplace.json
