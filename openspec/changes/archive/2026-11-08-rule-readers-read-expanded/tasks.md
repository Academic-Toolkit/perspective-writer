## 1. Consistency check and tests

- [x] 1.1 依 requirement「Skills that compare against existing rules read them expanded」，在 plugins/perspective-writer/scripts/check-contract-consistency.sh 新增斷言，並在 tests/plugin-rules.test.sh 加反例案例（暫存副本拿掉 save-feedback 的 expand 字樣，檢查以 1 結束並指名該檔）。驗證：三個 skill 修改前，斷言指名 draft-learner、role-calibrator、save-feedback。

## 2. Skills

- [x] 2.1 role-calibrator Step 2、draft-learner Step 3、save-feedback Step 4 加上對每個檔案執行 plugin-rules.sh expand、讀 stdout、告知附加揭露，寫入仍寫原始檔。驗證：check-contract-consistency.sh 通過；tests/plugin-rules.test.sh 在 bash 5 與 /bin/bash 3.2 下全過。

## 3. Release

- [x] 3.1 更新 plugins/perspective-writer/CHANGELOG.md（4.12.3），並把 plugins/perspective-writer/.claude-plugin/plugin.json 與 .claude-plugin/marketplace.json 的版本改為 4.12.3。驗證：jq 讀出兩處版本皆為 4.12.3。
