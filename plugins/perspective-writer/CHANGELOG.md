# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [4.11.0] - 2026-10-19

### Added
- **`agents/native-syntax-reader.md`、`agents/rules-auditor.md`**：plugin 自帶的兩個唯讀 subagent，frontmatter 設 `omitClaudeMd: true`、`tools: Read`、`model: sonnet`。註冊名是 `perspective-writer:native-syntax-reader` 與 `perspective-writer:rules-auditor`。
- `scripts/check-contract-consistency.sh` 第 6 組斷言：每個 agent 的 frontmatter 要有確切的 `omitClaudeMd: true`，要有 `tools:` 且不含 Bash／Edit／Write／NotebookEdit，且要有 skill 以 `perspective-writer:<name>` 派它。官方文件寫明不認識的 frontmatter 欄位會被靜默忽略，所以拼錯欄位名（例如 `omitClaudeMD`）時 agent 照常運作，只是回到載入 CLAUDE.md，沒有任何錯誤。已用暫存複本做負面測試：拼錯欄位與帶 `Bash` 的 `tools` 兩種都抓得到。

### Changed
- Phase 5e 的語序讀者與 Phase 5 的規則檔對照者，改派上述 plugin agent，不再用內建的 general-purpose。agent 不存在時（plugin 尚未重載）退回 general-purpose 並附一行說明；這是換派工對象，不是降級，也不算重試。
- 起因：2026-10-19 使用者指出，一般 subagent 啟動時會載入整個 CLAUDE.md 層級（含 `~/.claude/CLAUDE.md`），所以 5e「不知道這段文字是誰寫的」並不完全成立。實測用巢狀 `claude -p --plugin-dir` 載入本版原始碼（Claude Code 2.1.303），問兩種 subagent 同一題：context 裡有沒有只存在於使用者 `~/.claude/CLAUDE.md` 的字串。`native-syntax-reader` 回「沒有」，`general-purpose` 回「有」並指出來源檔。
- 版本需求：`omitClaudeMd` 需要 Claude Code v2.1.271 以上；更舊的版本無聲忽略該欄位，agent 仍可用，只是不隔離。
- 規格沒改：`native-syntax-reading` 本來就要求讀者不得收到使用者的指示，這次是讓實作符合它。

### 未改
- 5d 與 5f 第二層的潤稿 subagent 仍是 general-purpose。它們是改寫角色，不是盲讀角色；是否一併隔離另案處理。
- `rules-auditor` 沒有另做實測，它的 frontmatter 與 `native-syntax-reader` 相同，由斷言鎖住。

## [4.10.0] - 2026-10-02

### Added
- **規則檔逐條對照**（Phase 5 的一部分，有自己的 TaskCreate）。anti-pattern 表之後、5a 之前，派獨立 subagent，只給它 resolve 回傳的規則檔全文與草稿，找出草稿違反的條目；起草的 agent 逐條決定改或不改，不改的在 Phase 6 逐條列出讓使用者推翻。派不出 subagent 時不跳過，改由起草的 agent 把規則檔條目逐條列出命中／未命中／不適用。Phase 6 修改輪對改動句也執行。
- Phase 0 bootstrap 的 TaskCreate 清單新增 `phase5_subject_rules_audit`。
- 起因：2026-10-02 一封請示信，陳老師的規則檔早已寫「請示用『是否可能』比『是否可以』軟」，起草時讀過，草稿仍寫「是否可以」。規則檔在開頭讀一次，寫完沒有任何一步回頭對照。
- 做法由實測決定：同一份規則檔與同一份原草稿，「找出違反的條目」漏掉了「是否可以」；改成「每一條都寫出命中／未命中／不適用」後抓到它（189 條命中 4 條，其中 2 條是測試輸入沒帶署名檔的誤報）。代價是慢，規則檔很長時可按章節分給多個 subagent 並行。

### Changed
- Phase 5 表的 *Presupposed approval* 列補第三種載體：問句。「這趟旅費要用哪一個計畫的經費」預設了一定有經費；先問能不能，再問哪一個。起因同一封信，使用者寄出版把它改成「能不能申請補助？如果可以，用哪一個計畫的經費？」。
- EXTERNAL-CONSUMER CONTRACT 的 calibrate 不適用列舉加入 *Subject-rules Audit*（範圍說明，契約維持 v2）。

## [4.9.0] - 2026-10-02

### Added
- **Phase 5g: Redundancy Trim（對照順稿刪冗）**。5f 之後、Phase 6 呈現之前，起草的 agent 對照 5f 回稿（不論可否採用，只當參考），把原稿裡重複說同一件事的敘述刪掉或併掉，目的只有減少冗贅。動手條件三個，且都要成立：只刪併、不新增也不借順稿版的新措辭；每一處都指得出信裡另一處仍說了功能相同的話（重複的是標記句，不是不同項目的請求）；動過後仍通過 Phase 5（含 facet 增補列）與 5a，稱謂、署名、收尾格式、信裡要對方做的事、五類事實字串與段落數不動。結果就是 Phase 6 呈現的草稿，附前後差異與每處理由，使用者不同意就還原；動過的句子補跑 5e。5f 沒有回稿時不執行；Phase 6 修改輪不重跑。
- Phase 0 bootstrap 的 TaskCreate 清單新增 `phase5g_redundancy_trim`。
- 起因：2026-10-02 一封請示信，「有兩件事想向老師請示」之後兩項又各寫一次「想請老師指示」「想向老師請示」，同一個請示講了三次；5a 逐句看每句都站得住，重複要把句子放在一起比才看得出來。

### Changed
- 5f：整份捨棄仍把回稿交給 5g 當參考；Phase 6 的差異以 5g 之後的草稿為底。
- EXTERNAL-CONSUMER CONTRACT 的 calibrate 不適用列舉加入 *Redundancy Trim*（範圍說明，契約維持 v2）。

## [4.8.0] - 2026-10-02

### Added
- **Phase 5f: Smooth Pass（順稿）**。5e 之後、Phase 6 呈現之前，用一句簡單指令（「你可以順一下這封信嗎？」／"Can you smooth out this letter?"）請 5d 同一條管道把信順一遍，不附風格要求或凍結字串，但一起給與這封信有關的全部資訊，共五類：收件人與關係及規則檔全文、facet 的書信格律、信的目的與錨定事實、與收件人最近的往來原文、寫信者對這封信說過的話。回稿只是候選：5d 的 frozen span 全部仍在且次數不變、段落數不變，並且通過 anti-pattern 檢查、沒有新增、刪除或改變事實或請求，兩個條件都成立才算可採用，否則整份捨棄。可採用也先在 Phase 6 附差異給使用者看，使用者說採用才採用，採用後視同一次修改輪、對改動句跑 5e。指令在另開的新對話裡下達，不沿用 5d 的對話。降級同 5d 的 ladder，第二層也失敗才註記未執行，不阻斷交付；Phase 6 修改輪不重跑。
- Phase 0 bootstrap 的 TaskCreate 清單新增 `phase5f_smooth_pass`。
- 起因：2026-10-02 一封五句的請示信，只給信與一句指令時，回稿加了「一、二、」條列、把「我想」改成「我預計」（預設收件人同意）、改掉研討會全名的連字號與三層收尾，12 條凍結字串 7 條不符；附上五類資訊後這幾種改動都不再出現，仍有 6 條不符。資訊能減少最嚴重的改動，擋下問題的仍是驗證。

### Changed
- EXTERNAL-CONSUMER CONTRACT 的 calibrate 不適用列舉加入 *Smooth Pass*（範圍說明，契約維持 v2）：經由 calibrate 產生的草稿不經順稿。

## [4.7.0] - 2026-10-01

### Added
- **Phase 5e: Native-syntax Read**（#17）。5d 之後、Phase 6 呈現之前，派一個同家族的獨立 subagent 當讀者，只給它交付文字、語言標記與該語言的起點清單，不給草稿、來源或收件人脈絡；讀者逐句標出語序不像產出語言母語者會寫的句子，只標記、不改稿。採用的改寫須過 5d 的 frozen span 驗證；派不出讀者時照常交付並附一行說明。
- Phase 6 修改輪：每輪修改後、再次呈現前，對「改動句」加前後各一句重跑 5e（定義見 Phase 6，供 #19 沿用）。起因是 #17 的問題句是在修改時才加入，沒有經過任何檢查。
- `references/zh-Hant-syntax-checkpoints.md`：繁體中文起點清單，第一條「整個子句當主語，再接『是…的』」附 #17 實例；反例表列出使用者判為可接受、讀者不該標的句子。
- Phase 0 bootstrap 的 TaskCreate 清單新增 `phase5e_native_syntax_read`。

### Changed
- EXTERNAL-CONSUMER CONTRACT 的 calibrate 不適用列舉加入 *Native-syntax Read*（範圍說明，契約維持 v2）：經由 calibrate 產生的草稿不經語序檢查。
- Phase 5a 加第 6 項「每句先問讀者需不需要知道」（`0403bbb`，4.6.0 之後提交，先前未記入本檔）。

## [4.6.0] - 2026-09-09

### Added
- **Phase 5a: Natural-voice pass**（#15）。Phase 5 是黑名單，5a 補正面規範：簡單動詞、句長跟思路且允許重複、轉折詞只在需要時、不為像人而造假、收尾不重述。放在 5d 之前，因為外部潤稿模型分不出哪些重複是刻意的。
- `references/natural-writing-checklist.md`：自 OpenAI curated `humanwriting` 1.0.0 複製（上游改編自 Wikipedia「Signs of AI writing」，CC BY-SA 4.0），檔頭記來源與日期；不依賴 codex plugin cache。
- Phase 0 bootstrap 的 TaskCreate 清單新增 `phase5a_natural_voice_pass`，五項逐條確認成立才 completed。

## [4.5.0] - 2026-08-21

### Added

- **Anti-pattern: presupposed approval**（core）。與 4.4.0 的 forward-reference 是同一缺陷的
  兩種載體：那條是用**順序**預設同意，本條是用**語氣**（「我打算投稿」——對方還沒點頭，
  已用直述句講成事實）。判準：這件事對方若說不，我這句會不會變成先斬後奏？
- **WHY-first 適用到每一個小節**（email facet）。原本只規定信件開頭；多事項信的每個小節
  對讀者都是新的開始，同樣要先給目的再給細節。小節標題要寫「這段要對方做什麼」而非話題。
- **Group by subject, not by speech-act type**（email facet）。多事項信按「要對方做的 vs
  只是報告的」分組會把同一專案的事拆到信的兩端；應按事情本身分組。


## [4.4.0] - 2026-08-21

### Added

- **Anti-pattern: forward reference.** 前段依賴後段才會交代的事實，或預設了後段還在請求的許可。
  讀者是線性讀的；作者永遠看不出來，因為作者腦中整份文件是同時存在的。Sibling of the
  definite-reference row added in 4.3.0 — 差別在缺的東西不是讀者的記憶，而是文件自己還沒
  交代的後文。Found in use: 一封五事項的信把「文件簽名」排在「出國請假」之前，簽名那段寫
  「因為 8 月 30 日就出發」——而那趟出國的核可正是下一段要請的，等於在問之前先把答案填好。
  修法分兩級：一般前向指涉可改措辭；**若該資訊是後文正在請求核可的事，就升級成預設同意，
  必須改順序。**


## [4.3.0] - 2026-08-12

### Added

- **Anti-pattern: definite reference to context the reader may no longer hold.** "the handover",
  "that project", 「上次那份」 — a definite article carries an unchecked assumption that the
  recipient still holds the referent. Sibling of the temporal-anchor row and harder to catch,
  because the sentence reads perfectly well to the person who wrote it. Found in use: a draft
  said "Professor Chen has now finished the handover", relying on a detail mentioned once in
  passing twelve days earlier. Fix is to make the phrase self-contained, never to patch it with
  "as I mentioned earlier" — that hands the memory burden back to the recipient.
- **Phase 5d: Cross-model Polish** — a rewrite pass between Phase 5c and delivery. 5c
  *reviews* and returns findings; 5d *rewrites* and returns text. It runs a three-tier
  ladder (external model → independent subagent → plain delivery) in which **every tier
  exits to a delivered draft**; the writer sees the polished version as their first draft
  whenever a tier is available. The fallback tier must be an agent that did not write the
  draft — a second pass by the drafting agent is not a second viewpoint, and the whole
  reason for the step is the viewpoint.
- **Frozen-span obligation for the polish pass.** The request carries a list of literal
  spans covering the facts anchored during the understanding phases — time anchors,
  amounts, named handlers, process details, verbatim quotes. The returned text is verified
  span by span (still present, occurrence count unchanged) and rolled back to the
  pre-polish draft on any mismatch. This is the mechanism the consumer contract already
  requires of *its* callers, with the roles reversed: here the skill is the verifier, not
  the trusted rewriter. Style guidance is additional to the obligation, never a
  substitute — an external model cannot see the voice model or the anchors, and a
  fluent-but-drifted return is indistinguishable from a good one by inspection.

### Changed

- **Consumer contract: the calibrate-mode section mapping now names *Cross-model Polish*
  among the sections that do not apply.** This is an **additive clarification, not a
  BREAKING change** — calibrate mode behaves exactly as before and no consumer relied on
  anything that moved. The section is excluded for two mode-specific reasons: its exchange
  emits round-by-round output that the return shape in promise 7 forbids, and there is no
  human in that pass to read a polished result.
- **Phase 5c's "`codex-pro` is never required" non-goal is now scoped to Phase 5c**, in
  both the skill and the README. The clause itself is unchanged and was deliberately not
  deleted. What it forbids is promoting an optional plugin into a *precondition* for the
  ensemble re-check; Phase 5d treats the same plugins as a **degradable preference** —
  absent either one the ladder drops a tier and the draft still ships — so it does not
  violate the clause. Recording the scope prevents a future maintainer from resolving the
  apparent contradiction by deleting the line, which would silently remove the guard
  against declaring a circular plugin dependency.
- **Polish governance is resolved at run time by reference.** Model, reasoning effort and
  timeout come from the upstream governance contract at call time; this repository holds
  no model-name literal, and the resolution procedure is cited rather than copied. The
  upstream canonical document exists precisely so consumers do not embed divergent
  copies — a third copy would only add another place to age out of sync.

## [4.2.0] - 2026-08-07

### Changed

- **Calibrate mode now resolves from `recipient` when `recipient-rules` is absent.**
  The contract previously said *Resolve the Subject's Rules* "does not apply" to this
  mode. That was true of the **gate** and the **disclosure** — both need a human, and
  a programmatic pass has none — but it was written as though it were also true of the
  **lookup**, which needs no human at all. The three got collapsed into one sentence
  and calibrate lost the ability to find anything on its own.
- Consequence of the old wording: every consumer had to resolve the order itself.
  With three sources and placeholder-following, that is the same single-source defect
  this contract exists to remove — relocated outside this repository, where
  `check-contract-consistency.sh` cannot see it. Observed downstream: a consumer
  hardcoding the legacy single-file path found nothing in a workspace using
  skill-packaged rules, passed nothing, and produced an uncalibrated reply while the
  rules sat in a skill beside it.
- `MIN_PW_CONTRACT` floor moves to `4.2.0` for consumers that want to omit
  `recipient-rules`.

### Notes

- **Zero behavior change for a consumer that already passes `recipient-rules`.** This
  only adds a path where there previously was none.
- The gate and the disclosure remain out of scope for calibrate mode. What changed is
  that "the lookup applies" is now stated separately from "the gate does not".


## [4.1.0] - 2026-08-05

### Added

- **A mechanical check for contract consistency**, plus the repository's first CI
  workflow to run it on push to `main`. The repository uses direct-commit rather than
  pull requests, so push is the only automatic trigger point; a check that runs only
  when someone remembers to run it is the same as no check.
- Five assertions: no skill constructs a storage path inline (allowlisting only the
  contract and the two scripts that legitimately name paths), every contract section a
  skill cites exists, the reader-based split criterion still names its two exceptions
  with the reason, and the published contract still names the three outcome statuses.

### Notes

- **Deliberately shape-agnostic.** No assertion counts or names skills. The skill set
  went from four to five with the core/facet split and grows with each genre facet;
  count-based assertions would break on every such change, and a check that cries wolf
  gets ignored — the same as not having one.
- **What it cannot check**: whether a skill *follows* the contract it cites. That is
  prose read by a model and has no mechanical judgment. This check covers the layer
  below — that write sites and read sites address the same place — which is where the
  silent failure actually lives: rules get written and never load, and the only symptom
  is drafts that stop sounding like the writer.
- The migration script's idempotency is not covered here. That needs a scratch directory
  and file operations — a real test, not a grep — and this issue's scope was explicitly
  a mechanical net rather than a test suite.


## [4.0.0] - 2026-08-05

### Changed

- **BREAKING — the writing skill is now a core plus genre facets.** Everything that does
  not vary with genre stays in `perspective-writer`; correspondence conventions move to a
  new `perspective-writer-email` facet. A genre other than correspondence now has somewhere
  to put its own conventions instead of inheriting letter rules or getting no structure.
- **The core keeps its name.** A downstream consumer hardcodes both the invocation and the
  presence probe, and its integration degrades gracefully — renaming would have broken the
  entry with no error, replies posting uncalibrated and nothing saying so. "Core" is a role
  here, not a suffix.
- **The facet is loaded by the core's body, not by its own trigger.** There is no skill
  inheritance mechanism in this harness; linking is prose. Making completeness depend on two
  independent semantic triggers would double the chance of drafting with half the rules, and
  that failure is silent. The core determines the genre in Phase 0a and instructs the load —
  the same shape the rules-resolution step already uses.
- **The published calibration contract now names sections instead of phase numbers**, so the
  mapping survives this and any future reordering. The calibration entry itself is unchanged.
- The anti-pattern checklist was split row by row, not moved as a block: 16 genre-independent
  rows stay in the core, 2 correspondence rows move to the facet. Moving it wholesale would
  either strip the core of its general checks or leave letter rules embedded in it.

### Notes

- **Trade-off accepted: completeness is now compositional.** Before, one trigger guaranteed a
  letter had everything it needed. Now it needs the core plus one loaded facet. Loading by
  instruction rather than by trigger is the strongest available mitigation, but it is an
  instruction, not a gate — a reader that skips it produces a genre-independent draft. The
  guarantee is weaker than it was; that is the price of letting other genres exist.
- Only the correspondence facet ships. Other genres have nothing to move yet, and an empty
  facet would be shape without substance.


## [3.1.0] - 2026-08-05

### Changed

- **Consumer degradation-disclosure obligations raised from SHOULD to SHALL.** The
  contract defined a degradation signal (`status=generic`) and then left consuming it
  optional. For a failure whose output looks normal — a generic-register draft reads
  fine and is not distinguishable from a calibrated one by inspection — SHOULD reads as
  permission to skip, and a signal nobody is required to consume has defined nothing.
- Reading the status header is now stated as an obligation in its own right, not as an
  implication of the disclosure clause. A consumer that never reads the header cannot
  disclose anything and would otherwise have no stated requirement it visibly fails.

### Added

- The conditions that produce `status=generic` are now enumerated in the consumer
  contract, so a consumer can turn its disclosure into an actionable message rather than
  a generic warning. The list **points at** the *Outcome statuses* section of
  `references/rules-resolution.md` rather than restating the semantics, so the two cannot
  drift as the resolution order gains sources.

### Notes

- **No existing consumer breaks.** A consumer that does not read the status header keeps
  working exactly as before; it is merely now out of compliance. The change alters the
  normative basis, not any observed behavior — hence a minor bump, not a major one.
- Downstream implementation of the disclosure is tracked in the consumer's own
  repository, not here. This release supplies the normative backing that request cites.


## [3.0.0] - 2026-08-05

### Changed

- **BREAKING — writing rules now live behind a named resolution contract.** Where a
  subject's rules are stored, how a skill finds them, and what it must disclose are
  defined once in `references/rules-resolution.md`. All four skills cite that document
  instead of constructing paths of their own; previously each assembled its own path
  and the README described a location without describing how to resolve it.
- **BREAKING — per-subject rules move out of the injected project rules directory.**
  A subject now has a directory holding a genre-independent `core.md` plus on-demand
  genre facets, under a dot-prefixed namespace that is not injected into session
  context. Rules were previously a single file per recipient in a directory whose
  entire contents reach every session regardless of task.
- **BREAKING — external consumer contract v2.** The `recipient-rules` field now refers
  to a resolved location rather than a single file, and the three outcome statuses
  (`subject-specific` / `legacy` / `generic`) are named. Consumers that reconstruct the
  canonical location themselves must follow the resolution order. `MIN_PW_CONTRACT`
  moves to `3.0.0`.
- Rules split by **who reads them**, not by how narrowly they apply. Categories this
  plugin reads move into the namespace; code-comment style and general writing style
  stay in the injected directory, because no skill here reads them and injection is
  their only delivery mechanism. Moving those would remove their only reader silently.

### Added

- `references/rules-resolution.md` — the resolution contract: storage layout,
  resolution order, outcome statuses, dual-location conflict, composition precedence,
  split criterion, and the load gate.
- Load gate: drafting is refused when no resolution was performed. The gate binds to
  the lookup not having run, not to the rules file being absent, so genuine first
  contact remains a normal path — disclosed, not blocked.
- Skill-packaged subject rules recognised as a **current** arrangement, not a legacy
  one. A workspace may package a subject's rules as `.claude/skills/correspondence-<subject>/`;
  resolution treats it as that subject's core and returns `subject-specific`, so the
  load gate does not falsely disclose "no existing rules". One skill per genre for the
  same subject is a core-and-facet split expressed with skill boundaries, not a conflict.
- `scripts/migrate-rules.sh` — idempotent one-time migration. Converts each legacy
  rules file into a subject `core.md` and leaves a redirect placeholder at the legacy
  path so a consumer's existence check keeps passing. Creates no facets.

### Notes

- Legacy locations remain readable; an unmigrated workspace keeps working and is told
  migration is available. Migration is reversible.
- Known residual: a resolution run against an incorrect location returns `generic` and
  is indistinguishable from genuine first contact. The load gate narrows the failure
  space; it does not close this gap.


## [2.11.0] - 2026-07-19

### Added

- **EXTERNAL-CONSUMER CONTRACT (STABLE) — programmatic calibrate-draft entry (#1)** — other plugins can now invoke `perspective-writer:perspective-writer` with a structured `CALIBRATE-DRAFT REQUEST` block to calibrate an already-anchored draft for a human recipient (first consumer: issue-driven-dev `idd-comment --type=reply`, soft integration with graceful degrade). Contract single source = README "EXTERNAL-CONSUMER CONTRACT" section; consumers pin `MIN_PW_CONTRACT=2.11.0`. Phase mapping: Phase 1 skipped (no interview), Phase 2 fed by the consumer's `recipient-rules` path (absent → conservative generic register + explicit note), Phase 4 runs as a Revise pass over the provided draft, Phase 5 anti-pattern check unchanged, Phases 6/6b/7 skipped (single pass, unattended-friendly). HARD RULE: `frozen-anchors` (verbatim blockquotes, commit SHAs / PR refs, file / theorem / symbol references) survive byte-identical — calibration touches tone, register, and connective prose only, and never adds claims (Fabrication Trap rules unchanged). Return shape: the final message is the calibrated draft text itself — no wrapper narration, no file edits.

## [2.10.0] - 2026-07-18

### Changed
- **Extracted to standalone repo + marketplace [`PsychQuant/perspective-writer`](https://github.com/PsychQuant/perspective-writer)** (from the `psychquant-claude-plugins` umbrella; PsychQuant/psychquant-claude-plugins#116, motivated by PsychQuant/issue-driven-development#269 soft-integration). Install now via `claude plugin marketplace add PsychQuant/perspective-writer` + `claude plugin install perspective-writer@perspective-writer`. No skill content changes.

## [2.9.0] - 2026-07-09

### Added
- **Fabrication Trap — third failure mode: asserting unverified external facts.** Beyond (1) embellishing the writer's experience and (2) writing claims the user cannot defend, a sentence can point to a real external referent yet still be *wrong*: a paper's citation (journal/volume/pages/DOI), a person's current title, a law's name and date, an institution's official name, a statistic. The writer's memory — or a slide/transcript/draft source — can be off (a misremembered volume, an outdated title, a rounded-up statistic), and a recipient who knows the real figure stops trusting the whole letter. Fix: verify every external fact against an authoritative source (the journal's page, the institution's site, the government record) before it goes in; when memory or the draft source disagrees with the authoritative source, **the source wins**. Adds a third question to "The test". Real trigger: a meeting record drafted from an ASR transcript + presentation slides carried a spoken "gap ≈ 10 years" against the official 8.17→6.19, wrote "CRP" for the official "CRB", and cited a *Nature* paper whose volume/pages needed checking against the journal page — all caught only by web-verifying the external facts.

## [2.8.0] - 2026-05-20

### Added
- **Mode: Compose vs. Revise section** (#86): the skill now explicitly distinguishes drafting a new letter from iteratively revising an existing draft. Revise mode does not skip Phase 1-2 (the understanding phases where prior correspondence gets read). Real-world trigger: a host-inquiry letter was iteratively revised across many rounds while Phase 1-3 was silently skipped every round — the recipient's verbatim "If you contact me in a year" was softened into "at a later point" with no archive re-read, and downstream judgments built on the erased timeline drifted unrecoverably.
- **Phase 5 anti-pattern row — English sincerity-intensifier adverbs**: `sincerely`, `deeply`, `truly`, `genuinely`, `wholeheartedly`, `really`, `very much` modifying verbs of gratitude / hope / appreciation. Native English correspondence carries sincerity in the verb structure, not in adverbs; stacking intensifiers ("I deeply appreciate", "I sincerely hope") reads as ESL or AI. Fix is almost always deletion. `Sincerely yours` at sign-off is the one fixed-slot exception.
- **Mode-independent rule**: whenever prior correspondence with the recipient exists, reading it (Phase 1-2) is mandatory — covers the in-between case (reply to an incoming message when no draft yet exists).

### Changed
- **Phase 0 TaskList** (#86): `phase1_understand_writer` and `phase2_understand_recipient` task descriptions now explicitly require reading the recipient's archived correspondence, not merely asking whether it exists.
- **Phase 1 "Sources to check"** (#86): the recipient's prior-correspondence archive is no longer an "ask which are available" item; it is a mandatory-read-if-it-exists item. Other sources (blog / CV / etc.) remain ask-which.
- **Phase 2 paraphrasing rule** (#86): paraphrasing the recipient is now an explicit T-schema referent. Distinguishes "softening the tentativeness of a polite refusal" (allowed — keep `may be able to consider` tentative) from "erasing factual guidance" (not allowed — a concrete time / condition / instruction the recipient gave is a referent, not bookkeeping to be loosened away). Erasing one and every downstream judgment drifts silently — invisibly, because the reworded sentence still reads fine.
- **Phase 6b** (#86): cross-references the new Mode section. Each user edit begins another Revise pass; re-anchor to prior correspondence before reworking the draft again.
- **Span label correction** (#86 verify): the reading claim now says "Phase 1-2" (where prior correspondence actually gets read) rather than "Phase 1-3" (Phase 3 is Simulate and reads nothing). The "understanding phases" label is kept for the Phase 1-3 block as a whole.

## [2.7.0] - 2026-05-15

### Added
- **Phase 1 temporal anchors**: explicit questions for today's date, writer's lifecycle stage (onboarding week N / post-acceptance / mid-sabbatical etc.), and last contact/event with the recipient. Required before writing any time-relative phrasing ("recently", "前幾天", "上週", "last month"). Real-world trigger: AI defaulted to "陳老師前幾天提到..." when the actual conversation was 1 week earlier at a specific named meeting (storyline 會議, 2026-05-08). Recipient's memory of the event would not match "前幾天" → instant AI-generation tell.

### Changed
- **Golden Rule (T-schema)**: time phrasing now explicitly listed as a referent. Words like "recently / 前幾天 / 上週" must be anchored to a specific date verified with the writer, not guessed by the AI. Anchored phrasing ("5/8 在 storyline 會議時") carries the same warmth without the AI smell.
- **Phase 5 anti-pattern checklist**: added row for "vague temporal phrasing without verified anchor". Fix is to ask the writer for the specific date and replace with anchored form.

## [2.6.0] - 2026-05-07

### Added
- New `save-feedback` skill (#28): captures **conversational feedback** that user gives mid-draft into reusable rules. Complements `draft-learner` (which only triggers on file-modification system-reminders). Real-world gap: when user gives verbal tone/style/relationship/structure feedback in conversation and agent rewrites the file each round, no file diff is produced → draft-learner never fires → feedback evaporates at session end. `save-feedback` fills that gap with explicit invocation (`/perspective-writer:save-feedback`) or proactive trigger phrases ("存 feedback" / "把這些建議記下來"). 6-step workflow (scan conversation → classify → extract concrete rules with **Why** field → locate `.claude/rules/` file → write → confirm). Distinct from draft-learner per a side-by-side comparison table in the SKILL.md.

## [2.5.0] - (date unknown — please fill in)

### Changed
- Write letters, emails, autobiographies, and formal documents by simulating the writer's authentic voice.
- Uses Tarski's T-Schema to ensure every sentence has a concrete referent, and a 6-phase process (understand writer, understand recipient, simulate, write, anti-pattern check, iterate) to produce writing that sounds like a real person, not AI
