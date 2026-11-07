## 1. Tests first

- [ ] 1.1 在 tests/plugin-rules.test.sh 新增三個案例：來源在程式碼以外有格式正確的 include 行、格式錯的 include 行（皆期待結束碼 2、工作區沒有副本、stderr 指名來源）；include 行只在 fenced code block 裡（期待匯入成功、副本內容與來源相同）。驗證：在 plugin-rules.sh 尚未修改時執行，前兩個案例失敗。

## 2. Script

- [ ] 2.1 依 requirement「Import writes a provenance header and refuses to overwrite」，在 plugins/perspective-writer/scripts/plugin-rules.sh 的 cmd_import，resolve_ref 成功之後、任何目標檢查與寫入之前，以 has_unfenced "$MENTION_RE" "$R_FILE" 判斷，命中即 die 2，訊息指名 plugin:<ref> 並建議改用 include 行。驗證：1.1 的三個案例全部通過，既有案例仍通過，bash 5 與 /bin/bash 3.2 皆然。

## 3. Contract and docs

- [ ] 3.1 修改 plugins/perspective-writer/references/rules-resolution.md 的 import 說明：來源含 include 行時拒絕（結束碼 2）、理由（兩條取用路徑得到同一結果；副本只有一個檔，一個 sha256 即可凍結）、不追溯既有副本、副本裡使用者自己加的 include 照常展開。驗證：bash plugins/perspective-writer/scripts/check-contract-consistency.sh 通過。
- [ ] 3.2 修改 plugins/perspective-writer/skills/import-rules/SKILL.md 與 README.md：結束碼 2 多一種情況（來源含 include 行），遇到時告訴使用者改在工作區寫 include 行。驗證：grep 確認兩處都寫到。
- [ ] 3.3 更新 plugins/perspective-writer/CHANGELOG.md（4.12.2），並把 plugins/perspective-writer/.claude-plugin/plugin.json 與 .claude-plugin/marketplace.json 的版本改為 4.12.2。驗證：jq 讀出兩處版本皆為 4.12.2。
