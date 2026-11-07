## 1. 測試先行

- [x] 1.1 新增 tests/plugin-rules.test.sh，依「測試以假的已安裝紀錄驅動」在暫存目錄建立假的 plugin 目錄與 installed_plugins.json，以 `PW_INSTALLED_PLUGINS` 指向它，為第 2 節每個子任務各寫至少一個案例（比對 stdout、stderr 的 `pw:disclosure` 行與結束碼），失敗時印出案例名稱並以非零結束。驗證：在腳本尚不存在時執行 bash tests/plugin-rules.test.sh，所有案例失敗、結束碼非零。

## 2. plugin-rules.sh

- [x] 2.1 新增 plugins/perspective-writer/scripts/plugin-rules.sh 的 `expand` 子指令，依「單一腳本 plugin-rules.sh 是讀取已安裝 plugin 紀錄的唯一入口」與「展開輸出格式：來源標記與 stderr 揭露行」實作 requirement「Include line expands an installed plugin's rule file」：include 行換成被引用檔的全文並包上 `pw:source begin`／`pw:source end` 標記，其餘行原樣、順序不變。驗證：測試案例「plugin 已安裝、檔案存在」與 spec 的例子通過，stderr 無揭露、結束碼 0。
- [x] 2.2 依「include 行語法與 marketplace 省略規則」實作 requirement「Marketplace omitted only when unambiguous」：省略 `@<marketplace>` 時恰好一個同名鍵才展開，否則保留原行並回報 `include-unresolved` 與候選清單。驗證：測試案例「兩個同名 plugin」與「唯一同名」通過。
- [x] 2.3 實作 requirement「Missing plugin or file is disclosed, not dropped silently」：plugin 未安裝或檔案不存在時保留原行、回報 `include-unresolved` 並指名目標、結束碼 0。驗證：測試案例「plugin 未安裝」與「plugin 內缺檔」通過。
- [x] 2.4 實作 requirement「Nested include is not expanded」：被引用內容裡的 include 行原樣輸出在來源標記內，並回報 `include-nested`。驗證：測試案例「被引用檔再 include」通過。
- [x] 2.5 依「路徑限定在 plugin 根目錄內且只收 Markdown」實作 requirement「Included paths stay inside the plugin and are Markdown」：拒絕絕對路徑、含 `..` 片段、非 `.md`、以及解析符號連結後落在 installPath 之外的路徑，expand 回報 `include-unresolved`、import 以結束碼 2 拒絕。驗證：測試案例「路徑跳出 plugin」與「符號連結指向外部」通過，且外部檔案沒有被讀取。
- [x] 2.6 新增 `import` 子指令，依「匯入檔頭與過期判定只比對來源 sha256」實作 requirement「Import writes a provenance header and refuses to overwrite」：依 `--genre`／`--subject` 寫入對應路徑，第一行為 `pw:imported` 檔頭（plugin、version、path、sha256、date），stdout 印出寫入路徑；目標已存在且無 `--force` 時以結束碼 4 拒絕、檔案不變；slug 不符 `^[a-z0-9][a-z0-9-]*$` 以結束碼 2 拒絕。驗證：測試案例「匯入 genre 檔」「目標已存在」「slug 不合法」通過。
- [x] 2.7 實作 requirement「Stale import is disclosed by comparing the source hash」：expand 遇到 `pw:imported` 檔頭時重新計算來源 sha256，不同或來源不在就回報 `import-stale`；只改工作區副本不回報。驗證：測試案例「匯入後來源改變」「只改本地副本」「來源已移除」通過。
- [x] 2.8 實作 requirement「Only plugin-rules.sh reads the installed-plugin record」在腳本端的部分：檔案沒有 include 行也沒有匯入檔頭時不讀紀錄、原樣輸出、結束碼 0；需要紀錄時，讀不到或 `version` 不是 2 就以結束碼 3 失敗並在訊息中指名紀錄路徑；同一鍵多筆紀錄時取第一筆 installPath 存在者。驗證：測試案例「沒有 include 行且紀錄不存在」「紀錄形狀不符」通過。

- ASSUMPTION: 含 `pw:include` 但格式不對的 HTML 註解行，回報 `include-unresolved`，目標寫成 `line:<行號>`，原行照印、不讀紀錄。理由：若當成普通文字略過，那行要引用的規則就安靜缺席，正是 #25 要防的失敗。測試案例 `case_malformed_include_disclosed`。
- ASSUMPTION: include 行前後的空白可以容忍；路徑不得含空白（檔頭與 include 行都以空白分隔欄位）。
- ASSUMPTION: `import` 寫不出目標檔（目錄無法建立、權限不足）時以結束碼 2 結束；契約沒有列 I/O 失敗，2 是最接近的「目標路徑不可用」。
- ASSUMPTION: 腳本相容 macOS 內建的 bash 3.2（不用 `mapfile`、關聯陣列）；測試以 `PW_TEST_BASH=/bin/bash /bin/bash tests/plugin-rules.test.sh` 另跑一次。

## 3. 契約與 skill

- [x] 3.1 修改 plugins/perspective-writer/references/rules-resolution.md，依「主狀態維持三種，問題以附加揭露呈現」落實 requirement「Primary statuses stay three; problems are additional disclosures」：〈Storage layout〉加入 include 行、匯入檔頭與 plugin 端目錄慣例（`<plugin-root>/perspective-writer/genres/`、`subjects/`）；〈Resolution order〉寫明每個解析到的檔案都經 `plugin-rules.sh expand`；新增〈Additional disclosures〉列出封閉的四種揭露與告知義務；〈Redirect placeholder〉的「reported as unresolved」改為 `redirect-unresolved` 揭露；〈Composition precedence〉寫明 include 之後的工作區文字優先；〈Named resolution contract〉加入 import 操作。驗證：人工通讀確認狀態表仍是三種、四種揭露名稱與 spec 一致，且 bash plugins/perspective-writer/scripts/check-contract-consistency.sh 通過。
- [x] 3.2 修改 perspective-writer core skill 的 Phase 0b 與 Phase 5 規則對照段落，以及 plugins/perspective-writer/agents/rules-auditor.md，落實 requirement「Rules auditor receives expanded content with sources」：resolve 之後對每個檔案執行 expand，呈現草稿前逐則告知附加揭露；規則對照者拿到的是展開後的全文（含來源標記），不是 include 行；calibrate 模式照常展開、狀態標頭不變。驗證：grep 確認兩處都提到 `plugin-rules.sh expand` 與附加揭露，且 calibrate 段落的標頭格式未改。
- [x] 3.3 修改 save-feedback 與 draft-learner 的 persist 段落，依「persist 只寫工作區」落實 requirement「Persist writes only workspace files」：只寫工作區命名空間內的檔案，不寫 plugin 檔；目標檔含 include 行時新規則寫在其後；匯入副本可直接修改、保留檔頭。驗證：grep 確認兩個 skill 都寫明這三點。
- [x] 3.4 新增 plugins/perspective-writer/skills/import-rules/SKILL.md：使用者說「匯入某 plugin 的規則」時觸發，解析出 plugin 參照與 genre／subject 後呼叫 `plugin-rules.sh import`，回報寫入路徑；遇結束碼 4 時列出既有檔案、需使用者明確同意才帶 `--force`。驗證：人工檢查 frontmatter 的 name 與 description，且 skill 內只透過腳本讀 plugin，不自己組路徑。

## 4. 一致性檢查、文件與版本

- [ ] 4.1 修改 plugins/perspective-writer/scripts/check-contract-consistency.sh，新增斷言：除契約與 plugin-rules.sh 外，plugin 內沒有檔案提到 `installed_plugins.json` 或組出 plugin 安裝路徑。驗證：在乾淨的樹上執行通過；在暫存副本中把該檔名加進任一 skill 後執行，該斷言失敗並指名檔案。
- [ ] 4.2 更新 README.md（新增「從其他 plugin 提供規則」一節：目錄慣例、include 語法、import；Skills 表加入 import-rules）、plugins/perspective-writer/CHANGELOG.md（4.12.0 條目），並把 plugins/perspective-writer/.claude-plugin/plugin.json 與 .claude-plugin/marketplace.json 的版本同步改為 4.12.0。驗證：jq 讀出兩處版本皆為 4.12.0，README 的 include 範例與 spec 語法逐字一致。
- [ ] 4.3 全部完成後執行 bash tests/plugin-rules.test.sh 與 bash plugins/perspective-writer/scripts/check-contract-consistency.sh。驗證：兩者結束碼皆為 0。
