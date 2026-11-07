## Why

`plugin-rules.sh import` 逐字複製來源檔。來源若含 include 行，副本裡那一行成了工作區層級的 include，`expand` 會展開它；直接 include 同一個來源時，那一行屬於被引用內容，只回報 `include-nested`、不展開。同一份來源因取用方式不同，得到不同的展開深度。副本也只對最上層檔案算 sha256，被 include 的檔案改了不會判為 `import-stale`，「匯入可以凍結某一版」對這種來源不成立（#28）。

## What Changes

- `plugin-rules.sh import`：來源在程式碼以外含 include 行（格式正確或錯誤皆算）時，以結束碼 2 拒絕，不建立副本，訊息指名來源並建議改用 include。include 行只出現在 fence 或縮排程式碼裡的來源照常匯入。
- 規則解析契約的 import 一節寫明這個拒絕、理由與不追溯：本變更之前已匯入、含來源 include 行的副本，`expand` 照舊展開。
- import-rules skill 與 README 寫明這個結束碼 2 的情況。
- 匯入後使用者自己在副本裡加的 include 行，照工作區的 include 展開，不受影響。

## Non-Goals

- 不改直接 include 的行為（巢狀 include 仍只回報 `include-nested`）。
- 不追溯處理既有副本，也不對副本做遞迴雜湊。
- 不採 #28 列的另兩種語意：在副本裡區分「來自來源的 include」需要副本沒有的紀錄；保留不一致只是把問題寫進契約。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `plugin-provided-rules`: 匯入拒絕含 include 行的來源

## Impact

- Affected specs: `plugin-provided-rules`
- Affected code:
  - Modified: plugins/perspective-writer/scripts/plugin-rules.sh, tests/plugin-rules.test.sh, plugins/perspective-writer/references/rules-resolution.md, plugins/perspective-writer/skills/import-rules/SKILL.md, README.md, plugins/perspective-writer/CHANGELOG.md, plugins/perspective-writer/.claude-plugin/plugin.json, .claude-plugin/marketplace.json
