## Context

規則解析契約 `plugins/perspective-writer/references/rules-resolution.md` 是給模型讀的文字：skill 依它在工作區 `.claude/.perspective-writer/` 找 `genres/`、`subjects/` 的規則檔，並回報三種主狀態（subject-specific／legacy／generic）。`scripts/check-contract-consistency.sh` 只能檢查各 skill 引用同一份契約、不自己組路徑；skill 有沒有照做，沒有東西能驗證。

#25 要讓領域 plugin 提供規則：工作區用一行 include 引用，或把規則匯入成本地副本。已安裝 plugin 的位置記在 Claude Code 的 `installed_plugins.json`（`version: 2`，鍵為 `<name>@<marketplace>`，值為含 `installPath`、`version`、`scope` 的陣列）。這是 Claude Code 的內部格式。

repo 目前沒有測試套件。

## Goals / Non-Goals

**Goals:**

- 工作區規則檔能用一行 include 引用已安裝 plugin 的規則檔，解析時展開、標來源。
- 能把 plugin 規則匯入成工作區檔案，記下來源；來源改變時揭露過期。
- 展開與匯入是確定性的腳本，有測試涵蓋 #25 驗收條件 1–4。
- 三種主狀態與 EXTERNAL-CONSUMER CONTRACT v2 維持不變。
- 理順契約裡「exactly one of three statuses」與轉址那一節「reported as unresolved」的矛盾。

**Non-Goals:**

- 不改 calibrate 模式的狀態標頭（不加 include 相關屬性）；calibrate 模式下 include 照常展開，但失敗不反映在標頭。列為待決事項。
- 不歸檔 `subject-genre-rules-contract`、`consumer-generic-disclosure-obligation`、`skill-core-facet-split`（#26 處理）。
- 不提供 perspective-writer 以外的 skill 共用 plugin 規則的機制。
- 不支援從網址或任意檔案路徑引用規則，只限已安裝的 plugin。
- 不自動更新匯入檔；過期只揭露。

## Decisions

### 單一腳本 plugin-rules.sh 是讀取已安裝 plugin 紀錄的唯一入口

新增 `plugins/perspective-writer/scripts/plugin-rules.sh`，以子指令 `expand` 與 `import` 共用同一段查詢程式。skill 不直接讀 `installed_plugins.json`、不自己組 plugin 路徑。

替代方案：拆成兩支腳本，或讓 skill 依契約文字自己查。前者讓內部格式在兩處各讀一次；後者無法測試，且違反「不自己組路徑」的既有原則。

### include 行語法與 marketplace 省略規則

include 行的完整形式是 `<!-- pw:include plugin:<name>@<marketplace>/<path> -->`，獨佔一行。省略 `@<marketplace>` 時，只在已安裝紀錄裡恰好一個鍵以 `<name>@` 開頭才成立；零個或兩個以上都不展開，回報 `include-unresolved` 並列出候選。

替代方案：省略時取第一個同名 plugin。同名 plugin 的取捨不是腳本能判斷的，猜錯會讀到另一份規則而沒有訊號。

### 展開輸出格式：來源標記與 stderr 揭露行

`expand` 的 stdout 是展開後的全文：每段被引用的內容前後包上 `<!-- pw:source begin plugin:<key> version:<version> path:<path> -->` 與 `<!-- pw:source end -->`，其餘行原樣保留。揭露寫到 stderr，一行一則，格式為 `pw:disclosure <kind> <target> — <reason>`。

替代方案：輸出 JSON。規則對照者與起草者讀的是文字，把內容包在 JSON 裡反而要再拆一次；stderr 的固定前綴已足以讓測試與 skill 抓取。

### 匯入檔頭與過期判定只比對來源 sha256

`import` 寫入的檔案第一行是 `<!-- pw:imported plugin:<key> version:<version> path:<path> sha256:<hex> date:<YYYY-MM-DD> -->`。`expand` 遇到這種檔頭時，重新計算來源目前的 sha256；不同，或來源已不在，就回報 `import-stale`。工作區副本本身的內容不參與比對。

替代方案：比對副本與來源的差異。那會把使用者在本地的修改誤判成過期。

### 主狀態維持三種，問題以附加揭露呈現

契約的主狀態仍只有三種。新增封閉的四種附加揭露：`include-unresolved`、`include-nested`、`import-stale`（由腳本產生），以及 `redirect-unresolved`（由轉址解析產生，取代原本「reported as unresolved」的說法）。有附加揭露時，skill 在呈現草稿前逐則告知使用者；附加揭露不改變主狀態。

替代方案：新增第四種主狀態 `unresolved`。EXTERNAL-CONSUMER CONTRACT v2 的 consumer 依賴三種狀態的值域，新增狀態是 breaking change。

### 路徑限定在 plugin 根目錄內且只收 Markdown

include 與 import 的 `<path>` 必須是相對路徑、不含 `..` 片段、以 `.md` 結尾，且解析符號連結後的實際位置仍在該 plugin 的 `installPath` 之內。不符就回報 `include-unresolved`（expand）或以結束碼 2 拒絕（import）。

### persist 只寫工作區

`save-feedback` 與 `draft-learner` 的 persist 永遠寫工作區檔案，不寫進 plugin 檔。目標檔含 include 行時，新規則寫在 include 行之後，因此依組合優先序覆寫被引用的內容。匯入的副本可以直接修改，檔頭保留。

### 測試以假的已安裝紀錄驅動

`tests/plugin-rules.test.sh` 在暫存目錄建立假的 plugin 目錄與 `installed_plugins.json`，以環境變數 `PW_INSTALLED_PLUGINS` 指向它，執行 `expand` 與 `import` 並比對 stdout、stderr 與結束碼。不依賴本機實際安裝的 plugin。

## Implementation Contract

**介面**

- `plugin-rules.sh expand <file>`
  - stdout：展開後的全文（見〈展開輸出格式〉）。
  - stderr：零或多行 `pw:disclosure <kind> <target> — <reason>`。
  - 結束碼：0 成功（可以帶揭露）；2 用法錯誤或檔案不可讀；3 檔案含 include 行或匯入檔頭、但已安裝紀錄讀不到或不是 `version: 2` 的形狀。檔案沒有 include 行也沒有匯入檔頭時，不讀已安裝紀錄，原樣輸出、結束碼 0。
- `plugin-rules.sh import plugin:<name>[@<marketplace>]/<path> (--genre <slug> | --subject <slug> [--genre <slug>]) [--workspace <dir>] [--force]`
  - 目標：`--genre` 寫 `genres/<slug>.md`；`--subject` 寫 `subjects/<slug>/core.md`；兩者都給寫 `subjects/<subject>/<genre>.md`。`<slug>` 必須符合 `^[a-z0-9][a-z0-9-]*$`。
  - `--workspace` 預設為目前 git toplevel（取不到時為目前目錄）下的 `.claude/.perspective-writer`。
  - stdout：寫入的路徑。結束碼：0 成功；2 用法錯誤、參照無法解析或路徑不安全；3 已安裝紀錄形狀不符；4 目標已存在且未給 `--force`。
- 已安裝紀錄預設路徑 `$HOME/.claude/plugins/installed_plugins.json`，環境變數 `PW_INSTALLED_PLUGINS` 可覆寫。同一鍵有多筆紀錄時，取第一筆 `installPath` 存在的。

**驗收條件（對應 #25）**

1. 工作區檔只有一行 include、plugin 已安裝時，`expand` 輸出該 plugin 檔的全文並包上來源標記，stderr 無揭露。
2. plugin 未安裝或檔案不存在時，stderr 有 `include-unresolved` 並指名目標，結束碼 0。
3. 被引用的檔案裡又有 include 行時，該行原樣保留、不展開，stderr 有 `include-nested`。
4. `import` 寫出帶檔頭的檔案；之後改動來源檔，`expand` 該副本時 stderr 有 `import-stale`；只改副本不會。
5. `check-contract-consistency.sh` 通過，且新增的斷言能偵測到其他檔案讀取已安裝紀錄。

**範圍**

- In scope：腳本、`import-rules` skill、契約的儲存配置／解析順序／附加揭露／組合優先序／具名操作、Phase 0b 與規則對照者的輸入、persist 的寫入位置、一致性檢查、測試、README、CHANGELOG、版本。
- Out of scope：calibrate 標頭、歸檔三個舊 change、網址來源、自動更新匯入檔。

## Risks / Trade-offs

- [已安裝紀錄是 Claude Code 內部格式，可能改版] → 查詢集中在一支腳本，形狀不符時以結束碼 3 明確失敗，不猜。
- [skill 有沒有呼叫腳本，仍只能靠文字契約與一致性檢查間接把關] → 一致性檢查新增斷言，契約的 Phase 0b 段落寫明必須經由 `expand`。
- [被引用的 plugin 規則會成為起草時的指示] → 只收已安裝 plugin、路徑限定在其根目錄、只收 `.md`，並在來源標記與揭露中標出來源。
- [calibrate 模式下 include 失敗不會反映在標頭] → 列為待決事項；compose／revise 模式照常揭露。

## Migration Plan

純新增功能：既有工作區沒有 include 行時，`expand` 原樣輸出，行為不變。版本 4.11.0 → 4.12.0。回退方式：還原本 change 的 commit；工作區若已加入 include 行，回退後該行只是一行 HTML 註解，不影響其他規則。

## Open Questions

- calibrate 模式的狀態標頭是否要加 include 相關屬性（需要升 consumer contract 版本），另案處理。
